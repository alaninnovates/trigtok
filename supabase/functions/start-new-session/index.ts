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
