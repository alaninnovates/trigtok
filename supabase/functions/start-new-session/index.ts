import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { getSupabaseClient } from './supabase.ts';
import { getRedisClient } from './redis.ts';

Deno.serve(async (req) => {
    if (req.method !== 'GET') {
        return new Response('Method Not Allowed', { status: 405 });
    }

    const { user } = await getSupabaseClient(req);
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
            ex: 60 * 60, // 1 hour
        },
    );

    return new Response(
        JSON.stringify({ scroll_session_id: scrollSessionId }),
        {
            status: 200,
            headers: {
                'Content-Type': 'application/json',
            },
        },
    );
});
