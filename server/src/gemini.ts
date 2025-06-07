import { GoogleGenAI, Type } from '@google/genai';
import { config } from 'dotenv';
config();

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY || '' });

export const getExplanation = async (
    className: string,
    unit: string,
    topic: string,
): Promise<string> => {
    const { text } = await ai.models.generateContent({
        model: 'gemini-2.0-flash-001',
        contents: `You are a teacher of ${className}. Your student requests you to explain the topic "${topic}" in the unit "${unit}". Keep your explanation such that it can be spoken within a one-minute timeframe. Be as specific as possible, explaining what is relevant for the AP European History Exam detailed in the CED released in Fall of 2023. This explanation should be standalone, and can reference knowledge learned in previous units. Make your explanation understandable to a student without using complicated grammar or verbiage. Do not use any special characters, such as em-dashes, dashes, or colons. Your explanation should be able to be spoken out loud.`,
        config: {
            maxOutputTokens: 350,
        },
    });
    return text!;
};

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
    const processedText = answers
        .map(
            (answer, index) =>
                `Question ${index + 1}:\nQuestion: ${
                    answer.question
                }\nAnswer: ${answer.answer}\nPoint Value: ${
                    answer.point_value
                }\nRubric: ${answer.rubric}`,
        )
        .join('\n\n');
    const { text } = await ai.models.generateContent({
        model: 'gemini-2.0-flash-001',
        config: {
            responseMimeType: 'application/json',
            responseSchema: {
                type: Type.ARRAY,
                description:
                    'An array of grading results, one for each free-response question provided in the input.',
                items: {
                    type: Type.OBJECT,
                    required: ['points', 'feedback'],
                    properties: {
                        points: {
                            type: Type.NUMBER,
                            description:
                                "The number of points awarded for the student's answer, based on the rubric. Must be between 0 and the maximum point_value for the question.",
                        },
                        feedback: {
                            type: Type.STRING,
                            description:
                                "Constructive feedback explaining the points awarded or lost, referencing the rubric and student's answer, and suggesting improvements.",
                        },
                    },
                },
            },
        },
        contents: {
            role: 'user',
            parts: [
                {
                    text: `You are an expert AP teacher's assistant, skilled in grading free-response questions (FRQs) according to specific rubrics. Your task is to evaluate a student's answer against a given rubric and determine the points awarded, along with constructive feedback.

Here are the free-response questions with questions, student answers, their maximum point values, and the grading rubrics:

${processedText}

For each question, carefully compare the student's answer to the rubric.
1.  Determine the points the student earned for that specific answer. The points awarded should not exceed the point_value specified for the question. Be precise and fair in your scoring, adhering strictly to the rubric.
2.  Provide feedback that clearly explains why the student earned or lost points, referencing specific parts of the rubric and the student's answer. The feedback should be actionable and help the student understand how to improve. If the student earned full points, explain why their answer was excellent.

Your output should be a JSON array of objects, where each object contains the points awarded and feedback for the corresponding question.`,
                },
            ],
        },
    });
    return text
        ? JSON.parse(text)
        : ([] as {
              points: number;
              feedback: string;
          }[]);
};
