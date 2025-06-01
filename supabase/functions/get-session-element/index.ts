import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { getNextQuestionType, QuestionType } from './timeline.ts';
import { getExplanationFor } from './backend.ts';
import { getSupabaseClient } from '../_shared/supabase.ts';
import { getRedisClient } from '../_shared/redis.ts';
import { corsHeaders } from '../_shared/cors.ts';

Deno.serve(async (req) => {
    if (req.method == 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders });
    }
    if (req.method !== 'GET') {
        return new Response('Method Not Allowed', {
            headers: corsHeaders,
            status: 405,
        });
    }

    const { client, user } = await getSupabaseClient(req);
    const redis = getRedisClient();
    if (!user) {
        return new Response('Unauthorized', {
            headers: corsHeaders,
            status: 401,
        });
    }

    const url = new URL(req.url);
    const scrollSessionId = url.searchParams.get('scroll_session_id');
    const indexStr = url.searchParams.get('index');
    if (!scrollSessionId || !indexStr) {
        return new Response('Bad Request: Missing parameters', {
            headers: corsHeaders,
            status: 400,
        });
    }
    const index = parseInt(indexStr, 10);
    console.log('scrollSessionId', scrollSessionId);
    console.log('index', index);

    const userSessionId = await redis.get(
        `scroll_session:${scrollSessionId}:session-id`,
    );
    if (!userSessionId) {
        return new Response('Bad Request: Invalid scroll_session_id', {
            status: 400,
            headers: corsHeaders,
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
                'units(name, classes(name)), topic, type, data, bookmark, explanations(transcript, audio_url), multiple_choice_questions(stimulus, question, answers, correct_answer, explanations)',
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
            return new Response('Internal Server Error', {
                headers: corsHeaders,
                status: 500,
            });
        }
        let retData;
        switch (data.type) {
            case QuestionType.Explanation: {
                retData = {
                    type: data.type,
                    timelineId: timelineId,
                    unitName: data.units.name,
                    className: data.units.classes.name,
                    topic: data.topic,
                    bookmark: data.bookmark,
                    data: {
                        transcript: data.explanations.transcript,
                        audioUrl: data.explanations.audio_url,
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
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
    }

    const sessionMetadata = await redis.get(
        `scroll_session:${scrollSessionId}:metadata`,
    );

    if (!sessionMetadata) {
        return new Response('No session found', {
            headers: corsHeaders,
            status: 404,
        });
    }

    console.log('sessionMetadata', sessionMetadata);

    const { data: timeline, error: timelineError } = await client
        .from('study_timelines')
        .select(
            'id, units(id, name, classes(name)), topics (id, unit_id, topic, successor(id, unit_id, topic)), type, data, question_id',
        )
        .eq('session_id', userSessionId)
        .order('created_at', { ascending: false });

    console.log('sessionMetadata', sessionMetadata);
    console.log('timeline', timeline);

    if (!timeline) {
        console.error('Error fetching timeline:', timelineError);
        return new Response('No timeline found', {
            headers: corsHeaders,
            status: 404,
        });
    }

    const nextQuestionType = getNextQuestionType(
        timeline?.map((entry) => ({
            topic: entry.topics.topic,
            type: entry.type,
            data: entry.data,
            unitName: entry.units.name,
            className: entry.units.classes.name,
        })) ?? [],
    );

    console.log('nextQuestionType', nextQuestionType);

    const getNextTopic = () => {
        let unitId, topic;
        if (timeline.length == 0) {
            unitId = sessionMetadata.desired_unit_id;
            topic = {
                id: sessionMetadata.desired_topics[0].id,
                topic: sessionMetadata.desired_topics[0].topic,
            };
        } else {
            const latestEntry = timeline[0];
            console.log('latestEntry', latestEntry);
            unitId = latestEntry.topics.successor.unit_id;
            topic = {
                id: latestEntry.topics.successor.id,
                topic: latestEntry.topics.successor.topic,
            };
        }
        return { unitId, topic };
    };

    switch (nextQuestionType) {
        case QuestionType.Explanation: {
            const { unitId, topic } = getNextTopic();
            const explanation = await getExplanationFor(unitId, topic);
            const { data: inserted, error } = await client
                .from('study_timelines')
                .insert({
                    profile_id: user.id,
                    unit_id: unitId,
                    topic_id: topic.id,
                    type: QuestionType.Explanation,
                    session_id: userSessionId,
                    explanation_id: explanation.id,
                })
                .select('id')
                .single();
            if (!inserted || error) {
                console.error(
                    'Failed to insert explanation into timeline',
                    error,
                );
                return new Response('Internal Server Error', {
                    headers: corsHeaders,
                    status: 500,
                });
            }
            console.log(
                'Inserted explanation into timeline:',
                inserted,
                'for topic:',
                topic,
            );
            await redis.set(
                `scroll_session:${scrollSessionId}:${index}`,
                inserted.id,
                {
                    ex: 2 * 60 * 60,
                },
            );
            return new Response(
                JSON.stringify({
                    type: QuestionType.Explanation,
                    timelineId: inserted?.id,
                    unitName: sessionMetadata.unit_name,
                    className: sessionMetadata.class_name,
                    topic,
                    bookmark: false,
                    data: {
                        transcript: explanation.transcript,
                        audioUrl: explanation.audioUrl,
                    },
                }),
                {
                    status: 200,
                    headers: {
                        ...corsHeaders,
                        'Content-Type': 'application/json',
                    },
                },
            );
        }
        case QuestionType.MultipleChoice: {
            const { unitId, topic } = getNextTopic();
            const questionsAnswered = timeline
                .filter((entry) => entry.type === QuestionType.MultipleChoice)
                .filter((entry) => entry.topics.id === topic.id)
                .map((entry) => entry.question_id);
            const { data: question, error: mcqError } = await client
                .from('multiple_choice_questions')
                .select(
                    'id, stimulus, question, answers, correct_answer, explanations',
                )
                .eq('unit_id', unitId)
                .eq('topic', topic.id)
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
                if (mcqError) {
                    console.error(
                        'Error fetching multiple choice question:',
                        mcqError,
                    );
                }
                return new Response(
                    'No more questions available for this topic',
                    { headers: corsHeaders, status: 404 },
                );
            }
            const { data: inserted } = await client
                .from('study_timelines')
                .insert({
                    profile_id: user.id,
                    unit_id: unitId,
                    topic_id: topic.id,
                    type: QuestionType.MultipleChoice,
                    session_id: userSessionId,
                    question_id: question.id,
                })
                .select('id')
                .single();
            if (!inserted) {
                console.error(
                    'Failed to insert multiple choice question into timeline',
                    question,
                );
                return new Response('Internal Server Error', {
                    headers: corsHeaders,
                    status: 500,
                });
            }
            console.log(
                'Inserted multiple choice question into timeline:',
                inserted,
                'for topic:',
                topic,
            );
            await redis.set(
                `scroll_session:${scrollSessionId}:${index}`,
                inserted.id,
                {
                    ex: 60 * 60, // 1 hour
                },
            );
            return new Response(
                JSON.stringify({
                    type: QuestionType.MultipleChoice,
                    timelineId: inserted?.id,
                    unitName: sessionMetadata.unit_name,
                    className: sessionMetadata.class_name,
                    topic,
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
                    headers: {
                        ...corsHeaders,
                        'Content-Type': 'application/json',
                    },
                },
            );
        }
        case QuestionType.FreeResponse: {
            const { unitId, topic } = getNextTopic();
            const questionsAnswered = timeline
                .filter((entry) => entry.type === QuestionType.FreeResponse)
                .filter((entry) => entry.topics.id === topic.id)
                .map((entry) => entry.question_id);
            const { data: question, error: frqError } = await client
                .from('free_response_questions')
                .select('id, stimulus, questions, rubric, samples')
                .eq('unit_id', unitId)
                .eq('topic', topic.id)
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
                if (frqError) {
                    console.error(
                        'Error fetching free response question:',
                        frqError,
                    );
                }
                return new Response(
                    'No more questions available for this topic',
                    { headers: corsHeaders, status: 404 },
                );
            }
            const { data: inserted } = await client
                .from('study_timelines')
                .insert({
                    profile_id: user.id,
                    unit_id: unitId,
                    topic_id: topic.id,
                    type: QuestionType.FreeResponse,
                    session_id: userSessionId,
                    question_id: question.id,
                })
                .select('id')
                .single();
            if (!inserted) {
                console.error(
                    'Failed to insert free response question into timeline',
                    question,
                );
                return new Response('Internal Server Error', {
                    headers: corsHeaders,
                    status: 500,
                });
            }
            console.log(
                'Inserted free response question into timeline:',
                inserted,
                'for topic:',
                topic,
            );
            await redis.set(
                `scroll_session:${scrollSessionId}:${index}`,
                inserted.id,
                {
                    ex: 60 * 60, // 1 hour
                },
            );
            return new Response(
                JSON.stringify({
                    type: QuestionType.FreeResponse,
                    timelineId: inserted?.id,
                    unitName: sessionMetadata.unit_name,
                    className: sessionMetadata.class_name,
                    topic,
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
                    headers: {
                        ...corsHeaders,
                        'Content-Type': 'application/json',
                    },
                },
            );
        }
    }
});
