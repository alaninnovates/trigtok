export const getExplanationFor = async (unitId: number, topic: string) => {
    const res = await fetch(
        `${Deno.env.get(
            'API_URL',
        )}/generate?unitId=${unitId}&topic=${encodeURIComponent(topic)}`,
        {
            headers: {
                Authorization: `Bearer ${Deno.env.get('API_KEY')}`,
            },
        },
    );
    if (!res.ok) {
        throw new Error(`Failed to fetch explanation: ${res.statusText}`);
    }
    const data = await res.json();
    return {
        id: data.id,
        transcript: data.transcript,
        audioUrl: data.audio_url,
    };
};
