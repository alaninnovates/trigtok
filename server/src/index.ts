import Fastify from 'fastify';
import S from 'fluent-json-schema';
import { config } from 'dotenv';
import { readFileSync } from 'fs';
import { R2 } from 'node-cloudflare-r2';
config();

import { parseTranscript } from './transcript.js';
import { generateAudioAndSubtitles } from './tts.js';
import { Database } from './db.js';
import { getExplanation, gradeResponses } from './gemini.js';

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
        const { unitId, topicId, topic } = req.query as {
            unitId: number;
            topicId: number;
            topic: string;
        };
        const unitInfo = await db.getUnitInfo(unitId);
        if (!unitInfo) {
            return res.status(404).send({ error: 'Unit not found' });
        }
        const { className, unitName } = unitInfo;
        const explanationExists = await db.explanationExists(unitId, topicId);
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
            `Generating explanation for unit ${unitId}, topic id ${topicId}, topic ${topic}`,
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
            topicId,
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

const gradeSchema = S.object().prop(
    'answers',
    S.array().items(
        S.object()
            .prop('question', S.string())
            .prop('answer', S.string())
            .prop('point_value', S.number())
            .prop('rubric', S.string()),
    ),
);

fastify.post(
    '/grade',
    {
        schema: {
            body: gradeSchema,
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
        const { answers } = req.body as {
            answers: {
                question: string;
                answer: string;
                point_value: number;
                rubric: string;
            }[];
        };
        if (!answers || !Array.isArray(answers)) {
            return res
                .status(400)
                .send({ error: 'Bad Request: Invalid answers' });
        }
        const data = await gradeResponses(answers);
        return data;
    },
);

try {
    await fastify.listen({ port: parseInt(process.env.PORT!) });
} catch (err) {
    fastify.log.error(err);
    process.exit(1);
}
