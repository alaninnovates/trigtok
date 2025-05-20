import FfmpegCommand from 'fluent-ffmpeg';
import { generateAudioAndSubtitles } from './tts.js';
import { exec } from 'child_process';

// const text = `Okay, so remember Charles Darwin and his theory of evolution, with ideas like 'survival of the fittest' in the animal kingdom?
// Well, in the late 19th century, some thinkers, notably Herbert Spencer, took Darwin's biological ideas and incorrectly applied them to human societies. This became known as Social Darwinism.
// They argued that competition in society was natural, and that wealthy and powerful individuals, businesses, or even nations were successful because they were inherently 'fitter' or superior. Conversely, the poor or weaker groups were seen as 'unfit.'
// This belief was used to argue against government help for the poor, like welfare, because it supposedly interfered with this 'natural' order of weeding out the weak.
// Crucially for AP Euro, Social Darwinism became a major justification for New Imperialism. European powers argued they were 'fitter' and therefore had a right, even a duty, to dominate 'lesser' peoples in Africa and Asia, claiming racial and cultural superiority.
// So, Social Darwinism provided a pseudo-scientific basis for extreme inequalities, racism, and the aggressive nationalism that fueled imperialism during this period.`;
const text = `Alright, let's talk about the Protestant Reformation, which really kicks off in the early 16th century, building on trends from our Unit 1 period. Essentially, it was a major split within Western Christianity. Remember how Renaissance humanism encouraged looking at original sources and questioning established ideas? Well, thinkers, especially Christian Humanists like Erasmus in Northern Europe, began using these skills to criticize widespread problems in the Catholic Church, such as corruption and the sale of indulgences. The printing press, a new technology from this era, was crucial for spreading these criticisms and, later, new religious ideas. People like Martin Luther then challenged the Pope's authority, arguing the Bible alone was the source of truth and salvation came through faith, not good works or payments. This movement shattered Europe's religious unity, leading to new Protestant denominations and profound political changes.`;
const topic = 'unit1_protestant_reformation';
const { audioFilePath, subtitlesFilePath } = await generateAudioAndSubtitles(
    text,
    topic,
);
const videoFilePath = './videos/subwaysurfer_part2.mp4';

console.log(`Audio file path: ${audioFilePath}`);
console.log(`Subtitles file path: ${subtitlesFilePath}`);

// get length of audio file
const computeDuration = new Promise((resolve, reject) => {
    const { stdout } = exec(
        `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 ${audioFilePath}`,
    );
    stdout.on('data', (data) => {
        const duration = parseFloat(data);
        console.log(`Audio duration: ${duration} seconds`);
        resolve(duration);
    });
    stdout.on('error', (error) => {
        console.error(`Error getting audio duration: ${error}`);
        reject(error);
    });
});

const duration = await computeDuration;

import fs from 'fs';

const outputDir = './output';
if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
}
import path from 'path';
const outputFilePath = path.resolve(outputDir, `${topic}.mp4`);

const ffmpeg = new FfmpegCommand();
ffmpeg
    .input(videoFilePath)
    .input(audioFilePath)
    .input(subtitlesFilePath)
    .duration(duration + 2)
    .complexFilter([
        `[0:v]scale=1080:1920[scaled]`,
        `[scaled]subtitles=${subtitlesFilePath}:force_style='Alignment=10,OutlineColour=&H100000000,BorderStyle=3,Outline=1,Shadow=0,Fontsize=18'[v]`,
    ])
    .outputOptions([
        '-map',
        '[v]',
        '-map',
        '1:a',
        '-c:v',
        'libx264',
        '-c:a',
        'aac',
        '-shortest',
    ])
    .on('start', (commandLine) => {
        console.log('FFmpeg process started:', commandLine);
    })
    .on('progress', (progress) => {
        console.log('Processing:', progress.percent, '% done');
    })
    .on('end', () => {
        console.log('FFmpeg process finished successfully');
    })
    .on('error', (err) => {
        console.error('FFmpeg process failed:', err);
    })
    .save(outputFilePath);
