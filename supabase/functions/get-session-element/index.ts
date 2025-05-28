import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { getSupabaseClient } from './supabase.ts';
import { getRedisClient } from './redis.ts';
import { getNextQuestionType, QuestionType } from './timeline.ts';
import { getExplanationFor } from './backend.ts';

Deno.serve(async (req) => {
    if (req.method !== 'GET') {
        return new Response('Method Not Allowed', { status: 405 });
    }

    const { client, user } = await getSupabaseClient(req);
    const redis = getRedisClient();
    if (!user) {
        return new Response('Unauthorized', { status: 401 });
    }

    const url = new URL(req.url);
    const scrollSessionId = url.searchParams.get('scroll_session_id');
    const index = url.searchParams.get('index');
    if (!scrollSessionId || !index) {
        return new Response('Bad Request: Missing parameters', { status: 400 });
    }
    console.log('scrollSessionId', scrollSessionId);
    console.log('index', index);

    const userSessionId = await redis.get(
        `scroll_session:${scrollSessionId}:session-id`,
    );
    if (!userSessionId) {
        return new Response('Bad Request: Invalid scroll_session_id', {
            status: 400,
        });
    }
    console.log('userSessionId', userSessionId);

    const timelineId = await redis.get(
        `scroll_session:${scrollSessionId}:${index}`,
    );
    if (timelineId) {
        const { data, error } = await client
            .from('study_timelines')
            .select(
                'units(name, classes(name)), topic, type, data, heart, bookmark, explanations(transcript, audio_url), multiple_choice_questions(stimulus, question, answers, correct_answer, explanations)',
            )
            .eq('id', timelineId)
            .limit(1)
            .single();
        if (error) {
            console.error(
                'Error fetching timeline entry:',
                error,
                'timelineId:',
                timelineId,
            );
            return new Response('Internal Server Error', { status: 500 });
        }
        let retData;
        switch (data.type) {
            case QuestionType.Explanation: {
                retData = {
                    type: data.type,
                    timelineId: timelineId,
                    unitName: data.units[0].name,
                    className: data.units[0].classes[0].name,
                    topic: data.topic,
                    heart: data.heart,
                    bookmark: data.bookmark,
                    data: {
                        transcript: data.explanations[0].transcript,
                        audioUrl: data.explanations[0].audio_url,
                    },
                };
                break;
            }
            case QuestionType.MultipleChoice: {
                break;
            }
            case QuestionType.FreeResponse: {
                break;
            }
        }
        return new Response(JSON.stringify(retData), {
            status: 200,
            headers: { 'Content-Type': 'application/json' },
        });
    }

    const { data: sessionMetadata } = await client
        .from('user_sessions')
        .select(
            'id, desired_unit_id, units(name, classes(name)), desired_topics',
        )
        .eq('id', userSessionId)
        .limit(1)
        .single();

    if (!sessionMetadata) {
        return new Response('No session found', { status: 404 });
    }

    const { data: timeline } = await client
        .from('study_timelines')
        .select(
            'id, units(id, name, topics, next_unit, classes(name)), topic, type, data, question_id',
        )
        .eq('session_id', sessionMetadata.id)
        .order('created_at', { ascending: false });

    console.log('sessionMetadata', sessionMetadata);
    console.log('timeline', timeline);

    if (!timeline) {
        return new Response('No timeline entries found', { status: 404 });
    }

    const nextQuestionType = getNextQuestionType(
        timeline?.map((entry) => ({
            topic: entry.topic,
            type: entry.type,
            data: entry.data,
            unitName: entry.units[0].name,
            className: entry.units[0].classes[0].name,
        })) ?? [],
    );

    console.log('nextQuestionType', nextQuestionType);

    switch (nextQuestionType) {
        case QuestionType.Explanation: {
            let unitId, topic;
            if (timeline.length == 0) {
                unitId = sessionMetadata.desired_unit_id;
                topic = sessionMetadata.desired_topics[0];
            } else {
                const latestEntry = timeline[0];
                if (
                    sessionMetadata.desired_topics.indexOf(
                        latestEntry.topic,
                    ) ===
                    sessionMetadata.desired_topics.length - 1
                ) {
                    // last topic in the list, go to next unit
                    unitId = latestEntry.units[0].next_unit;
                    topic = sessionMetadata.desired_topics[0];
                } else {
                    unitId = latestEntry.units[0].id;
                    topic = latestEntry.topic;
                }
            }
            const explanation = await getExplanationFor(unitId, topic);
            const { data: inserted } = await client
                .from('study_timelines')
                .insert({
                    profile_id: user.id,
                    unit_id: unitId,
                    topic,
                    type: QuestionType.Explanation,
                    session_id: sessionMetadata.id,
                    explanation_id: explanation.id,
                })
                .select('id')
                .single();
            return new Response(
                JSON.stringify({
                    type: QuestionType.Explanation,
                    timelineId: inserted?.id,
                    unitName: sessionMetadata.units[0].name,
                    className: sessionMetadata.units[0].classes[0].name,
                    topic,
                    heart: false,
                    bookmark: false,
                    data: {
                        transcript: explanation.transcript,
                        audioUrl: explanation.audioUrl,
                    },
                }),
                {
                    status: 200,
                    headers: { 'Content-Type': 'application/json' },
                },
            );
        }
        case QuestionType.MultipleChoice: {
            let unitId: number, topic: string;
            let questionsAnswered = [];
            if (timeline.length == 0) {
                unitId = sessionMetadata.desired_unit_id;
                topic = sessionMetadata.desired_topics[0];
            } else {
                const latestEntry = timeline[0];
                unitId = latestEntry.units[0].id;
                topic = latestEntry.topic;
                questionsAnswered = timeline
                    .filter(
                        (entry) => entry.type === QuestionType.MultipleChoice,
                    )
                    .filter((entry) => entry.topic === topic)
                    .map((entry) => entry.question_id);
            }
            const { data: question } = await client
                .from('multiple_choice_questions')
                .select(
                    'id, stimulus, question, answers, correct_answer, explanations',
                )
                .eq('unit_id', unitId)
                .eq('topic', topic)
                .not('id', 'in', `(${questionsAnswered.join(',')})`)
                .limit(1)
                .single();
            if (!question) {
                console.error(
                    'No more questions available for this topic',
                    topic,
                    'Seen questions:',
                    questionsAnswered,
                    'Unit ID:',
                    unitId,
                );
                return new Response(
                    'No more questions available for this topic',
                    { status: 404 },
                );
            }
            const { data: inserted } = await client
                .from('study_timelines')
                .insert({
                    profile_id: user.id,
                    unit_id: unitId,
                    topic,
                    type: QuestionType.MultipleChoice,
                    session_id: sessionMetadata.id,
                    question_id: question.id,
                })
                .select('id')
                .single();
            return new Response(
                JSON.stringify({
                    type: QuestionType.MultipleChoice,
                    timelineId: inserted?.id,
                    unitName: sessionMetadata.units[0].name,
                    className: sessionMetadata.units[0].classes[0].name,
                    topic,
                    heart: false,
                    bookmark: false,
                    data: {
                        stimulus: question.stimulus,
                        question: question.question,
                        answers: question.answers,
                        correctAnswer: question.correct_answer,
                        explanations: question.explanations,
                    },
                }),
                {
                    status: 200,
                    headers: { 'Content-Type': 'application/json' },
                },
            );
        }
        case QuestionType.FreeResponse: {
            let unitId: number, topic: string;
            let questionsAnswered = [];
            if (timeline.length == 0) {
                unitId = sessionMetadata.desired_unit_id;
                topic = sessionMetadata.desired_topics[0];
            } else {
                const latestEntry = timeline[0];
                unitId = latestEntry.units[0].id;
                topic = latestEntry.topic;
                questionsAnswered = timeline
                    .filter((entry) => entry.type === QuestionType.FreeResponse)
                    .filter((entry) => entry.topic === topic)
                    .map((entry) => entry.question_id);
            }
            const { data: question } = await client
                .from('free_response_questions')
                .select('id, stimulus, questions, rubric, samples')
                .eq('unit_id', unitId)
                .eq('topic', topic)
                .not('id', 'in', `(${questionsAnswered.join(',')})`)
                .limit(1)
                .single();
            if (!question) {
                console.error(
                    'No more questions available for this topic',
                    topic,
                    'Seen questions:',
                    questionsAnswered,
                    'Unit ID:',
                    unitId,
                );
                return new Response(
                    'No more questions available for this topic',
                    { status: 404 },
                );
            }
            const { data: inserted } = await client
                .from('study_timelines')
                .insert({
                    profile_id: user.id,
                    unit_id: unitId,
                    topic,
                    type: QuestionType.FreeResponse,
                    session_id: sessionMetadata.id,
                    question_id: question.id,
                })
                .select('id')
                .single();
            return new Response(
                JSON.stringify({
                    type: QuestionType.FreeResponse,
                    timelineId: inserted?.id,
                    unitName: sessionMetadata.units[0].name,
                    className: sessionMetadata.units[0].classes[0].name,
                    topic,
                    heart: false,
                    bookmark: false,
                    data: {
                        stimulus: question.stimulus,
                        questions: question.questions,
                        rubric: question.rubric,
                        samples: question.samples,
                    },
                }),
                {
                    status: 200,
                    headers: { 'Content-Type': 'application/json' },
                },
            );
        }
    }
});
