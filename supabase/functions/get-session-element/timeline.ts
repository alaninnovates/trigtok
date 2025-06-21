export enum QuestionType {
    MultipleChoice = 'mcq',
    FreeResponse = 'frq',
    Explanation = 'explanation',
}

interface McqData {
    selectedAnswer: number;
    correct: boolean;
}

interface FrqData {
    answers: {
        text: string;
        ai_feedback: string;
        points: number;
    }[];
    ai_grade: number;
    total_points_possible: number;
}

interface ExplanationData {}

export interface TimelineEntry {
    topic: string;
    type: QuestionType;
    data: McqData | FrqData | ExplanationData;
    unitName: string;
    className: string;
}

export interface SessionMetadata {
    unit_name: string;
    class_name: string;
    desired_unit_id: number;
    require_correctness: boolean;
    question_types: QuestionType[];
    questions_per_topic: Record<string, number>;
    desired_topics: { id: number; topic: string }[];
}

const defaultQuestionsPerTopic = {
    [QuestionType.MultipleChoice]: 4,
    [QuestionType.FreeResponse]: 2,
};

export const getNextQuestionType = (
    timeline: TimelineEntry[],
    metadata: SessionMetadata,
): {
    type: QuestionType;
    nextTopic: boolean;
} => {
    if (timeline.length === 0) {
        console.log(metadata.question_types);
        return {
            type: metadata.question_types[0],
            nextTopic: false,
        };
    }

    const lastEntry = timeline[0];
    console.log('last entry', lastEntry);

    const mcqCount = timeline.filter(
        (entry) => entry.type === QuestionType.MultipleChoice,
    ).length;
    const frqCount = timeline.filter(
        (entry) => entry.type === QuestionType.FreeResponse,
    ).length;

    const lastQuestion = timeline[0];
    console.log('last question', lastQuestion);
    const lastQuestionCorrect =
        lastQuestion.data == null
            ? false
            : lastQuestion.type === QuestionType.MultipleChoice
            ? (lastQuestion.data as McqData).correct
            : lastQuestion.type === QuestionType.FreeResponse
            ? (lastQuestion.data as FrqData).ai_grade /
                  (lastQuestion.data as FrqData).total_points_possible >=
              0.5
            : false;

    if (!lastQuestionCorrect && metadata.require_correctness) {
        return {
            type: lastEntry.type,
            nextTopic: false,
        };
    }

    if (
        lastEntry.type === QuestionType.MultipleChoice &&
        (metadata.questions_per_topic[QuestionType.MultipleChoice] ||
            defaultQuestionsPerTopic[QuestionType.MultipleChoice]) > mcqCount
    ) {
        return {
            type: QuestionType.MultipleChoice,
            nextTopic: false,
        };
    }

    if (
        lastEntry.type === QuestionType.FreeResponse &&
        (metadata.questions_per_topic[QuestionType.FreeResponse] ||
            defaultQuestionsPerTopic[QuestionType.FreeResponse]) > frqCount
    ) {
        return {
            type: QuestionType.FreeResponse,
            nextTopic: false,
        };
    }

    const nextTypeIndex = metadata.question_types.indexOf(lastEntry.type) + 1;
    if (nextTypeIndex < metadata.question_types.length) {
        return {
            type: metadata.question_types[nextTypeIndex],
            nextTopic: false,
        };
    }
    return {
        type: metadata.question_types[0],
        nextTopic: true,
    };
};
