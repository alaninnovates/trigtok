import { createWriteStream } from 'node:fs';
import { Readable } from 'node:stream';

const categories = ['minecraft', 'subwaysurfer', 'sliceit'];

// download from part 1-20 for each category
for (const category of categories) {
    for (let i = 1; i <= 20; i++) {
        const url = `https://brainrot-vscode-ext.sdan.io/videos_15/${category}_part${i}.mp4`;
        const filePath = `videos/${category}_part${i}.mp4`;

        if (typeof fetch === 'undefined')
            throw new Error('Fetch API is not supported.');

        const response = await fetch(url);

        if (!response.ok) throw new Error('Response is not ok.');

        const writeStream = createWriteStream(filePath);

        const readable = Readable.fromWeb(response.body);

        readable.pipe(writeStream);

        await new Promise((resolve, reject) => {
            readable.on('end', resolve);
            readable.on('error', reject);
        });
    }
}
