export enum QuestionType {
    MultipleChoice = 'mcq',
    FreeResponse = 'frq',
    Explanation = 'explanation',
}

export interface TimelineEntry {
    topic: string;
    type: QuestionType;
    data:
        | {
              // when type is mcq
              selectedAnswer: string;
              correct: boolean;
          }
        | {
              // when type is frq
              answer: string;
              correct: boolean;
              ai_feedback: number;
          }
        | Record<PropertyKey, never>; // when type is explanation
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

    const lastEntry = timeline[timeline.length - 1];

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
    const lastQuestion = timeline[timeline.length - 1];
    const lastQuestionCorrect = lastQuestion.data.correct;

    if (!lastQuestionCorrect) {
        return lastQuestion.type;
    }

    const mcqToFrqRatio = 3 / 1;
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
