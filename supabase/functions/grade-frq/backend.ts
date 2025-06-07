export const gradeResponses = async (
    answers: {
        question: string;
        answer: string;
        point_value: number;
        rubric: string;
    }[],
): Promise<
    {
        points: number;
        feedback: string;
    }[]
> => {
    const res = await fetch(`${Deno.env.get('API_URL')}/grade`, {
        headers: {
            Authorization: `Bearer ${Deno.env.get('API_KEY')}`,
            'Content-Type': 'application/json',
        },
        method: 'POST',
        body: JSON.stringify({ answers }),
    });
    if (!res.ok) {
        throw new Error(
            `Failed to fetch grades: ${res.status} ${
                res.statusText
            } ${await res.text()}`,
        );
    }
    return await res.json();
};
