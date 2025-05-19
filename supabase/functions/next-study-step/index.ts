import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { getSupabaseClient } from './supabase.ts';
import { getNextQuestionType } from './timeline.ts';

Deno.serve(async (req) => {
    const { client, user } = await getSupabaseClient(req);
    if (!user) {
        return new Response('Unauthorized', { status: 401 });
    }

    const { data: sessionMetadata } = await client
        .from('user_sessions')
        .select('id, desired_unit_id, desired_topics')
        .eq('profile_id', user.id)
        .order('created_at', { ascending: false })
        .limit(1)
        .single();

    if (!sessionMetadata) {
        return new Response('No session found', { status: 404 });
    }

    const { data: timeline } = await client
        .from('study_timelines')
        .select('units(name, classes(name)), topic, type, data')
        .eq('session_id', sessionMetadata.id)
        .order('created_at', { ascending: false });

    console.log('sessionMetadata', sessionMetadata);
    console.log('timeline', timeline);

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

    return new Response('ok');
});
