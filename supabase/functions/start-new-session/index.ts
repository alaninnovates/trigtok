import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { getSupabaseClient } from '../_shared/supabase.ts';
import { getRedisClient } from '../_shared/redis.ts';
import { corsHeaders } from '../_shared/cors.ts';

Deno.serve(async (req) => {
    if (req.method == 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders });
    }

    if (req.method !== 'GET') {
        return new Response('Method Not Allowed', { status: 405 });
    }

    const { client, user } = await getSupabaseClient(req);
    const redis = getRedisClient();
    if (!user) {
        return new Response('Unauthorized', { status: 401 });
    }

    const url = new URL(req.url);
    const userSessionId = url.searchParams.get('user_session_id');
    if (!userSessionId) {
        return new Response('Bad Request: Missing parameters', { status: 400 });
    }

    const scrollSessionId = crypto.randomUUID();

    await redis.set(
        `scroll_session:${scrollSessionId}:session-id`,
        userSessionId,
        {
            ex: 2 * 60 * 60,
        },
    );

    const { data: sessionMetadata, error: userSessionError } = await client
        .from('user_sessions')
        .select(
            'desired_unit_id, units(name, classes(name)), require_correctness, question_types, questions_per_topic',
        )
        .eq('id', userSessionId)
        .limit(1)
        .single();

    const { data: desiredTopics, error: topicsError } = await client
        .from('user_sessions_topics')
        .select('id, topics(id, topic)')
        .eq('user_session_id', userSessionId)
        .order('id', { ascending: true });

    if (!sessionMetadata || !desiredTopics) {
        console.error(
            'Error fetching session metadata or desired topics:',
            userSessionError,
            topicsError,
        );
        return new Response('Bad Request: Invalid session data', {
            status: 400,
        });
    }

    await redis.set(
        `scroll_session:${scrollSessionId}:metadata`,
        JSON.stringify({
            unit_name: sessionMetadata.units.name,
            class_name: sessionMetadata.units.classes.name,
            desired_unit_id: sessionMetadata.desired_unit_id,
            require_correctness: sessionMetadata.require_correctness,
            question_types: sessionMetadata.question_types,
            questions_per_topic: sessionMetadata.questions_per_topic,
            desired_topics: desiredTopics.map((t) => ({
                id: t.topics.id,
                topic: t.topics.topic,
            })),
        }),
        {
            ex: 2 * 60 * 60,
        },
    );

    console.log(
        `New scroll session created: ${scrollSessionId} for user session: ${userSessionId}`,
    );

    return new Response(
        JSON.stringify({ scroll_session_id: scrollSessionId }),
        {
            status: 200,
            headers: {
                ...corsHeaders,
                'Content-Type': 'application/json',
            },
        },
    );
});
