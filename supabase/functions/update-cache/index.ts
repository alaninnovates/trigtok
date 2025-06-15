import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { getSupabaseClient } from '../_shared/supabase.ts';
import { getRedisClient } from '../_shared/redis.ts';
import { corsHeaders } from '../_shared/cors.ts';

Deno.serve(async (req) => {
    if (req.method == 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders });
    }
    if (req.method !== 'POST') {
        return new Response('Method Not Allowed', {
            headers: corsHeaders,
            status: 405,
        });
    }

    const { client, user } = await getSupabaseClient(req);
    const redis = getRedisClient();
    console.log('user', user);
    // if (!client) {
    //     return new Response('Unauthorized', {
    //         headers: corsHeaders,
    //         status: 401,
    //     });
    // }

    const body = await req.json();

    if (body.record.type !== 'mcq' && body.record.type !== 'frq') {
        return new Response('Unsupported question type', {
            headers: corsHeaders,
            status: 400,
        });
    }

    const scrollSessionId = body.record.data.scroll_session_id;

    const keys = await redis.keys(`scroll_session:${scrollSessionId}:*`);
    const index = keys.length - 3;
    console.log(`Updating scroll session ${scrollSessionId} at index ${index}`);
    const existing = await redis.get(
        `scroll_session:${scrollSessionId}:${index}`,
    );
    console.log(existing);

    let newData;

    if (body.record.type === 'mcq') {
        newData = {
            ...existing.data,
            selectedAnswer: body.record.data.selected_answer,
            correct: body.record.data.correct,
        };
    } else if (body.record.type === 'frq') {
        newData = {
            ...existing.data,
            answers: body.record.data.answers,
            ai_grade: body.record.data.ai_grade,
            total_points_possible: body.record.data.total_points_possible,
        };
    }

    await redis.set(
        `scroll_session:${scrollSessionId}:${index}`,
        JSON.stringify({
            ...existing,
            data: newData,
        }),
        {
            ex: 2 * 60 * 60,
        },
    );

    return new Response(JSON.stringify({ ok: true }), {
        headers: { 'Content-Type': 'application/json' },
    });
});
