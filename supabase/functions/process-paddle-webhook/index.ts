import 'jsr:@supabase/functions-js/edge-runtime.d.ts';

console.log('Hello from Functions!');

Deno.serve(async (req) => {
    const { name } = await req.json();
    const data = {
        message: `Hello ${name}!`,
    };

    return new Response(JSON.stringify(data), {
        headers: { 'Content-Type': 'application/json' },
    });
});
