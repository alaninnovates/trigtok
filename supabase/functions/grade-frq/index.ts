import 'jsr:@supabase/functions-js/edge-runtime.d.ts';

import { getSupabaseClient } from '../_shared/supabase.ts';
import { corsHeaders } from '../_shared/cors.ts';
import { gradeResponses } from './backend.ts';

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
    const { user } = await getSupabaseClient(req);
    if (!user) {
        return new Response('Unauthorized', {
            status: 401,
            headers: corsHeaders,
        });
    }
    const { answers } = (await req.json()) as {
        answers: {
            question: string;
            answer: string;
            point_value: number;
            rubric: string;
        }[];
    };
    if (!answers || !Array.isArray(answers)) {
        return new Response('Bad Request: Invalid answers', {
            status: 400,
            headers: corsHeaders,
        });
    }
    console.log(`User ID: ${user.id}, Grading ${JSON.stringify(answers)}`);
    const data = await gradeResponses(answers);
    console.log(
        `User ID: ${user.id}, Graded responses: ${JSON.stringify(data)}`,
    );
    return new Response(JSON.stringify(data), {
        headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
        },
    });
});
