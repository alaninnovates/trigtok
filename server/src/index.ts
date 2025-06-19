import Fastify from 'fastify';
import S from 'fluent-json-schema';
import { config } from 'dotenv';
import { readFileSync } from 'fs';
import { R2 } from 'node-cloudflare-r2';
import multipart from '@fastify/multipart';
import cors from '@fastify/cors';
import { v4 as uuidv4 } from 'uuid';
config();

import { parseTranscript } from './transcript.js';
import { generateAudioAndSubtitles } from './tts.js';
import { Database } from './db.js';
import { getExplanation, gradeResponses } from './gemini.js';
import { getSupabaseClient } from './supabase.js';

const fastify = Fastify({
    logger: {
        file: './logs/server.log',
        level: 'info',
        transport: {
            target: 'pino-pretty',
            options: {
                translateTime: 'HH:MM:ss Z',
                ignore: 'pid,hostname',
            },
        },
    },
});

const r2 = new R2({
    accountId: process.env.R2_ACCOUNT_ID || '',
    accessKeyId: process.env.R2_ACCESS_KEY_ID || '',
    secretAccessKey: process.env.R2_SECRET_ACCESS_KEY || '',
});
const bucket = r2.bucket('audio');
const userContentBucket = r2.bucket('user-content');
const db = new Database(
    process.env.SUPABASE_URL || '',
    process.env.SUPABASE_SERVICE_KEY || '',
);

fastify.register(multipart, {
    limits: {
        fileSize: 10 * 1024 * 1024, // 10 MB,
        files: 5,
    },
});
fastify.register(cors, {
    origin: '*',
    methods: ['GET', 'POST'],
});

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
        req.log.info(
            `Stored explanation for unit ${unitId}, topic id ${topicId}, data: ${JSON.stringify(
                data,
            )}`,
        );
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

fastify.post('/new-set', async (req, res) => {
    const authHeader = req.headers.authorization;
    const { user } = await getSupabaseClient(authHeader || '');
    if (!authHeader || !user) {
        return res.status(401).send({ error: 'Unauthorized' });
    }

    const parts = req.parts();
    const files: string[] = [];
    const fields: Record<string, string> = {};
    for await (const part of parts) {
        if (part.type === 'file') {
            const buffer = await part.toBuffer();
            const fileExtension = part.filename
                ? part.filename.split('.').pop() || ''
                : '';
            req.log.info(
                `Received file: ${part.filename}, extension: ${fileExtension}`,
            );
            if (
                !fileExtension ||
                !['jpg', 'jpeg', 'png', 'pdf'].includes(fileExtension)
            ) {
                return res.status(400).send({
                    error: 'Unsupported file type.',
                });
            }
            const fileName = `${uuidv4()}.${fileExtension}`;
            try {
                const uploaded = await userContentBucket.uploadStream(
                    buffer,
                    fileName,
                );
                req.log.info(`File uploaded: ${JSON.stringify(uploaded)}`);
                files.push(
                    `https://user-content.trigtok.com/${uploaded.objectKey}`,
                );
            } catch (error) {
                req.log.error('Failed to upload file: ' + error);
                return res.status(500).send({ error: 'Failed to upload file' });
            }
        } else if (part.type === 'field') {
            fields[part.fieldname] = part.value as string;
        }
    }

    if (
        files.length === 0 &&
        (!fields.content || fields.content.trim() === '')
    ) {
        req.log.error('No files/content uploaded');
        return res.status(400).send({ error: 'No files/content uploaded' });
    }
    if (!fields.title || !fields.subject) {
        req.log.error('Missing required fields: title, subject');
        return res.status(400).send({
            error: 'Missing required fields: title, subject',
        });
    }
    const { title, subject, content } = fields;
    const { success, data } = await db.createSet(
        title,
        subject,
        content,
        files,
        user.id,
    );
    if (!success) {
        req.log.error('Failed to create set: ' + data);
        return res.status(500).send({ error: 'Failed to create set' });
    }
    req.log.info(`Set created successfully: ${JSON.stringify(data)}`);
    return res.status(200).send(data);
});

try {
    await fastify.listen({ port: parseInt(process.env.PORT!) });
} catch (err) {
    fastify.log.error(err);
    process.exit(1);
}
