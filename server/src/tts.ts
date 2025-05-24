import { exec } from 'child_process';
import fs from 'fs';

interface GenerateAudioAndSubtitlesResult {
    audioFilePath: string;
    subtitlesFilePath: string;
}

/***
 * Generates audio and subtitles using edge-tts.
 * @param {string} text - The text to convert to speech.
 * @param {string} outputName - The base name for the output files.
 * @returns {Promise<{ audioFilePath: string, subtitlesFilePath: string }>} - A promise that resolves with the paths of the generated audio and subtitles files.
 */
export const generateAudioAndSubtitles = async (
    text: string,
    outputName: string,
): Promise<GenerateAudioAndSubtitlesResult> => {
    const audioFilePath: string = `./output/${outputName}.mp3`;
    const subtitlesFilePath: string = `./output/${outputName}.srt`;

    const replaced: string = text.replaceAll('\n', ' ').replaceAll('"', ' ');

    const command: string = `edge-tts --rate=+50% --voice en-US-AndrewNeural --text "${replaced}" --write-media ${audioFilePath} --write-subtitles ${subtitlesFilePath}`;

    return new Promise<GenerateAudioAndSubtitlesResult>((resolve, reject) => {
        exec(command, (error: Error | null, stdout: string, stderr: string) => {
            if (error) {
                console.error(
                    `Error generating audio and subtitles: ${error.message}`,
                );
                reject(error);
            } else if (stderr) {
                console.error(`stderr: ${stderr}`);
                reject(new Error(stderr));
            } else {
                // postprocess the subtitles
                const fileText: string = fs.readFileSync(
                    subtitlesFilePath,
                    'utf8',
                );
                const postprocessedSubtitles: string = postprocessSubtitles(
                    text.replaceAll('\n', ' '),
                    fileText,
                );
                fs.writeFileSync(subtitlesFilePath, postprocessedSubtitles);
                resolve({ audioFilePath, subtitlesFilePath });
            }
        });
    });
};

const postprocessSubtitles = (
    inputText: string,
    replacedText: string,
): string => {
    const inputTextSplit: string[] = inputText.split(' ');
    let matchedIndex: number = 0;
    const finalLines: string[] = [];
    for (const line of replacedText.split('\n')) {
        if (line.match(/^\d{2}:\d{2}:\d{2}/) || line.trim() === '') {
            finalLines.push(line);
            continue;
        }

        const lineSplit: string[] = line.split(' ');
        const finalLine: string[] = [];
        for (const word of lineSplit) {
            if (replaced(inputTextSplit[matchedIndex]) === replaced(word)) {
                finalLine.push(inputTextSplit[matchedIndex]);
                matchedIndex++;
            } else {
                finalLine.push(word);
            }
        }
        finalLines.push(finalLine.join(' '));
    }
    return finalLines.join('\n');
};

const replaced = (word: string) => {
    // console.log(word);
    return word
        .replaceAll('.', '')
        .replaceAll(',', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll('?', '')
        .replaceAll('!', '')
        .replaceAll(':', '');
};
