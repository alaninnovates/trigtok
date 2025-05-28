import Fastify from 'fastify';
import S from 'fluent-json-schema';
import { config } from 'dotenv';
import { readFileSync } from 'fs';
import { R2 } from 'node-cloudflare-r2';
config();

import { parseTranscript } from './transcript.js';
import { generateAudioAndSubtitles } from './tts.js';
import { Database } from './db.js';
import { getExplanation } from './gemini.js';

const fastify = Fastify({
    logger: {
        file: './logs/server.log',
        level: 'info',
    },
});

const r2 = new R2({
    accountId: process.env.R2_ACCOUNT_ID || '',
    accessKeyId: process.env.R2_ACCESS_KEY_ID || '',
    secretAccessKey: process.env.R2_SECRET_ACCESS_KEY || '',
});
const bucket = r2.bucket('audio');
const db = new Database(
    process.env.SUPABASE_URL || '',
    process.env.SUPABASE_SERVICE_KEY || '',
);

fastify.get('/', async () => {
    return { ok: true };
});

const generateQuerySchema = S.object()
    .prop('unitId', S.number())
    .prop('topic', S.string());

fastify.get(
    '/generate',
    {
        schema: {
            querystring: generateQuerySchema,
        },
    },
    async (req, res) => {
        const authHeader = req.headers.authorization;
        if (
            !authHeader ||
            !authHeader.startsWith('Bearer ') ||
            authHeader !== `Bearer ${process.env.API_KEY}`
        ) {
            return res.status(401).send({ error: 'Unauthorized' });
        }
        const { unitId, topic } = req.query as {
            unitId: number;
            topic: string;
        };
        const unitInfo = await db.getUnitInfo(unitId);
        if (!unitInfo) {
            return res.status(404).send({ error: 'Unit not found' });
        }
        const { className, unitName, topics } = unitInfo;
        if (!topics.includes(topic)) {
            return res.status(404).send({ error: 'Topic not found' });
        }
        const explanationExists = await db.explanationExists(unitId, topic);
        if (explanationExists.error) {
            req.log.error(
                'Failed to check explanation existence because: ' +
                    explanationExists.data,
            );
            return res
                .status(500)
                .send({ error: 'Failed to check explanation existence' });
        }
        if (explanationExists.exists) {
            return explanationExists.data[0];
        }
        req.log.info(
            `Generating explanation for unit ${unitId}, topic ${topic}`,
        );
        const explanation = await getExplanation(className, unitName, topic);
        req.log.info(`Generated explanation: ${explanation}`);
        const sanitizedTopic = topic.replace(/[^a-z0-9]/gi, '_').toLowerCase();
        const { audioFilePath, subtitlesFilePath } =
            await generateAudioAndSubtitles(
                explanation,
                `${unitId}-${sanitizedTopic}`,
            );
        const transcriptFile = readFileSync(subtitlesFilePath, 'utf8');
        const transcript = parseTranscript(transcriptFile);
        const uploaded = await bucket.uploadFile(
            audioFilePath,
            `${unitId}-${sanitizedTopic}.mp3`,
        );
        req.log.info(
            `Generated audio, file uploaded at ${JSON.stringify(uploaded)}`,
        );
        const { success, data } = await db.storeExplanation(
            unitId,
            topic,
            transcript,
            `https://audio.trigtok.com/${uploaded.objectKey}`,
        );
        if (!success) {
            req.log.error('Failed to store explanation because: ' + data);
            return res
                .status(500)
                .send({ error: 'Failed to store explanation' });
        }
        return data;
    },
);

try {
    await fastify.listen({ port: parseInt(process.env.PORT!) });
} catch (err) {
    fastify.log.error(err);
    process.exit(1);
}
