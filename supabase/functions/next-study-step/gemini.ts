import { GoogleGenAI } from 'npm:@google/genai';

const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY') ?? '';

const ai = new GoogleGenAI({ apiKey: GEMINI_API_KEY });

export const getExplanation = async (unit: string, topic: string) => {
    const { text } = await ai.models.generateContent({
        model: 'gemini-2.0-flash-001',
        contents: `You are a teacher of AP European History. Your student requests you to explain the topic "${topic}" in the unit "${unit}". Keep your explanation such that it can be spoken within a one-minute timeframe. Be as specific as possible, explaining what is relevant for the AP European History Exam detailed in the CED released in Fall of 2023. This explanation should be standalone, and can reference knowledge learned in previous units. Make your explanation understandable to a student without using complicated grammar or verbiage. Your explanation should be able to be spoken out loud.`,
        config: {
            maxOutputTokens: 350,
        },
    });
    console.log('GEMINI API response:', text);
    return text;
};
