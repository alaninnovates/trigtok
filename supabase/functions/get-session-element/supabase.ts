import { createClient } from 'jsr:@supabase/supabase-js@2';

export const getSupabaseClient = async (req: Request) => {
    const client = createClient(
        Deno.env.get('SUPABASE_URL') ?? '',
        Deno.env.get('SUPABASE_ANON_KEY') ?? '',
        {
            global: {
                headers: { Authorization: req.headers.get('Authorization')! },
            },
        },
    );
    const authHeader = req.headers.get('Authorization')!;
    const token = authHeader.replace('Bearer ', '');
    const { data } = await client.auth.getUser(token);
    return {
        client,
        user: data.user,
    };
};
