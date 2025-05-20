const { FFScene, FFText, FFCreator, FFVideo } = require('ffcreatorlite');
const path = require('path');
const { generateAudioAndSubtitles } = require('./speakify');

const width = 1080;
const height = 1920;

const outputDir = path.join(__dirname, './output/');
const cacheDir = path.join(__dirname, './cache/');

const creator = new FFCreator({
    cacheDir,
    outputDir,
    width,
    height,
    log: true,
});

const scene = new FFScene();
scene.setBgColor('#ff0000');

const video = new FFVideo({
    path: './videos/subwaysurfer_part1.mp4',
    x: 0,
    y: 0,
    width,
    height,
    // 1440 × 2560 to 1080 x 1920
    scale: 0.75,
});
scene.addChild(video);

// const order = [
//     { text: 'this is the', seconds: 0 },
//     { text: 'first text', seconds: 2 },
//     { text: '', seconds: 3 },
//     { text: 'this is the', seconds: 4 },
//     { text: 'second text', seconds: 6 },
//     { text: '', seconds: 7 },
//     { text: 'this is the', seconds: 8 },
//     { text: 'third text', seconds: 10 },
// ];
// for (let i = 0; i < order.length; i++) {
//     const item = order[i];
//     const textWidth = item.text.length * 60;
//     const text = new FFText({
//         x: width / 2 - textWidth / 2,
//         y: (height / 8) * 3,
//         fontSize: 120,
//     });
//     text.setStyle({ align: 'center' });
//     text.setText(item.text);
//     text.setColor('#ffffff');
//     text.setBackgroundColor('#000000');
//     text.addEffect('fadeIn', 0, item.seconds);
//     if (i !== order.length - 1) {
//         text.addEffect('fadeOut', 0, order[i + 1].seconds);
//     } else {
//         text.addEffect('fadeOut', 0, item.seconds + 1);
//     }
//     scene.addChild(text);
// }

scene.setDuration(order[order.length - 1].seconds + 2);
creator.addChild(scene);

creator.start();

creator.on('progress', (e) => {
    console.log(`FFCreatorLite progress: ${(e.percent * 100) >> 0}%`);
});

creator.on('complete', (e) => {
    console.log(
        `FFCreatorLite completed: \n USEAGE: ${e.useage} \n PATH: ${e.output} `,
    );
});
