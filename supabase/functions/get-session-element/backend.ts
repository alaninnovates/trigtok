export const getExplanationFor = async (
    unitId: number,
    topic: {
        id: number;
        topic: string;
    },
) => {
    const res = await fetch(
        `${Deno.env.get('API_URL')}/generate?unitId=${unitId}&topicId=${
            topic.id
        }&topic=${encodeURIComponent(topic.topic)}`,
        {
            headers: {
                Authorization: `Bearer ${Deno.env.get('API_KEY')}`,
            },
        },
    );
    if (!res.ok) {
        throw new Error(
            `Failed to fetch explanation: ${res.status} ${
                res.statusText
            } ${await res.text()}`,
        );
    }
    const data = await res.json();
    return {
        id: data.id,
        transcript: data.transcript,
        audioUrl: data.audio_url,
    };
};
