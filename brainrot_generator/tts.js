import { exec } from 'child_process';
import fs from 'fs';
/***
 * Generates audio and subtitles using edge-tts.
 * @param {string} text - The text to convert to speech.
 * @param {string} outputName - The base name for the output files.
 * @returns {Promise<{ audioFilePath: string, subtitlesFilePath: string }>} - A promise that resolves with the paths of the generated audio and subtitles files.
 */
export const generateAudioAndSubtitles = async (text, outputName) => {
    const audioFilePath = `./output/${outputName}.mp3`;
    const subtitlesFilePath = `./output/${outputName}.srt`;

    const replaced = text.replaceAll('\n', ' ').replaceAll('"', ' ');

    const command = `edge-tts --rate=+50% --voice en-US-AndrewNeural --text "${replaced}" --write-media ${audioFilePath} --write-subtitles ${subtitlesFilePath}`;

    return new Promise((resolve, reject) => {
        exec(command, (error, stdout, stderr) => {
            if (error) {
                console.error(
                    `Error generating audio and subtitles: ${error.message}`,
                );
                reject(error);
            } else if (stderr) {
                console.error(`stderr: ${stderr}`);
                reject(new Error(stderr));
            } else {
                console.log('Audio and subtitles generated successfully.');
                // postprocess the subtitles
                const fileText = fs.readFileSync(subtitlesFilePath, 'utf8');
                const postprocessedSubtitles = postprocessSubtitles(
                    text.replaceAll('\n', ' '),
                    fileText,
                );
                console.log(
                    `Postprocessed subtitles: ${postprocessedSubtitles}`,
                );
                fs.writeFileSync(subtitlesFilePath, postprocessedSubtitles);
                resolve({ audioFilePath, subtitlesFilePath });
            }
        });
    });
};

const postprocessSubtitles = (inputText, replacedText) => {
    // "un-replace" the quotation marks and punctuation removed.
    // the replacedText has quotes and punctuation removed. add it back based on the inputText
    const inputTextSplit = inputText.split(' ');
    let matchedIndex = 0;
    const finalLines = [];
    for (const line of replacedText.split('\n')) {
        if (line.match(/^\d{2}:\d{2}:\d{2}/) || line.trim() === '') {
            finalLines.push(line);
            continue;
        }

        const lineSplit = line.split(' ');
        const finalLine = [];
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

const replaced = (word) => {
    // console.log(word);
    return word
        .replaceAll('.', '')
        .replaceAll(',', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll('?', '')
        .replaceAll('!', '');
};
