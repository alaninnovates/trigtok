import { createClient } from '@supabase/supabase-js';
import { config } from 'dotenv';
config();

export const getSupabaseClient = async (authHeader: string) => {
    const client = createClient(
        process.env['SUPABASE_URL'] ?? '',
        process.env['SUPABASE_ANON_KEY'] ?? '',
        {
            global: {
                headers: { Authorization: authHeader },
            },
        },
    );
    const token = authHeader.replace('Bearer ', '');
    const { data } = await client.auth.getUser(token);
    return {
        client,
        user: data.user,
    };
};
