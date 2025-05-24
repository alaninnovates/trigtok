export interface Duration {
    hours: number;
    minutes: number;
    seconds: number;
    milliseconds: number;
}

export interface TranscriptElement {
    index: number;
    text: string;
    start: Duration;
    end: Duration;
}

export type Transcript = TranscriptElement[];

export const parseTranscript = (srtContent: string): Transcript => {
    const lines = srtContent.split(/\r?\n/);

    const transcriptItems = [];
    let index = 0;
    let startTime = null;
    let endTime = null;
    let text = '';

    for (const line of lines) {
        if (line.trim() === '') {
            if (startTime && endTime && text.trim() !== '') {
                transcriptItems.push({
                    index,
                    start: startTime,
                    end: endTime,
                    text: text.trim(),
                });
            }
            index = 0;
            startTime = null;
            endTime = null;
            text = '';
            continue;
        }

        if (index === 0) {
            index = parseInt(line, 10) || 0;
        } else if (!startTime && !endTime) {
            const match = line.match(
                /(\d{2}:\d{2}:\d{2},\d{3}) --> (\d{2}:\d{2}:\d{2},\d{3})/,
            );
            if (match) {
                startTime = parseDuration(match[1]);
                endTime = parseDuration(match[2]);
            }
        } else {
            text += `${line} `;
        }
    }

    // Add the last item if it exists
    if (startTime && endTime && text.trim() !== '') {
        transcriptItems.push({
            index,
            start: startTime,
            end: endTime,
            text: text.trim(),
        });
    }

    return transcriptItems;
};

const parseDuration = (time: string): Duration => {
    const [hours, minutes, seconds, milliseconds] = time
        .split(/[:,]/)
        .map(Number);
    return {
        hours,
        minutes,
        seconds,
        milliseconds,
    };
};
