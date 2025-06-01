import { getSystemErrorMap } from 'node:util';

export enum QuestionType {
    MultipleChoice = 'mcq',
    FreeResponse = 'frq',
    Explanation = 'explanation',
}

interface McqData {
    selectedAnswer: string;
    correct: boolean;
}

interface FrqData {
    answer: string;
    ai_grade: number;
    total_points_possible: number;
    ai_feedback: string;
}

interface ExplanationData {}

export interface TimelineEntry {
    topic: string;
    type: QuestionType;
    data: McqData | FrqData | ExplanationData;
    unitName: string;
    className: string;
}

export const getNextQuestionType = (
    timeline: TimelineEntry[],
): QuestionType => {
    // algorithm: determine the next question type based on the timeline
    // based on correctness of previous questions
    if (timeline.length === 0) {
        return QuestionType.Explanation;
    }

    const lastEntry = timeline[0];

    console.log('last entry', lastEntry);

    if (lastEntry.type === QuestionType.Explanation) {
        return QuestionType.MultipleChoice;
    }

    // give ratio mcq:frq of 3:1
    // if prev q incorrect, repeat the same type
    const mcqCount = timeline.filter(
        (entry) => entry.type === QuestionType.MultipleChoice,
    ).length;
    const frqCount = timeline.filter(
        (entry) => entry.type === QuestionType.FreeResponse,
    ).length;
    const lastQuestion = timeline[0];
    console.log('last question', lastQuestion);
    const lastQuestionCorrect =
        lastQuestion.data && lastQuestion.type === QuestionType.MultipleChoice
            ? (lastQuestion.data as McqData).correct
            : lastQuestion.type === QuestionType.FreeResponse
            ? (lastQuestion.data as FrqData).ai_grade >=
              Math.floor(
                  ((lastQuestion.data as FrqData).total_points_possible / 3) *
                      2,
              )
            : false;

    if (!lastQuestionCorrect) {
        return lastQuestion.type;
    }

    const mcqToFrqRatio = 4 / 1;
    const totalQuestions = mcqCount + frqCount;
    const totalRatio = mcqCount / (frqCount || 1);

    if (totalQuestions > 0 && totalRatio < mcqToFrqRatio) {
        return QuestionType.MultipleChoice;
    }
    if (totalQuestions > 0 && totalRatio >= mcqToFrqRatio) {
        return QuestionType.FreeResponse;
    }

    return QuestionType.Explanation;
};
