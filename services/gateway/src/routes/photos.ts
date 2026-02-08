import { randomUUID } from 'crypto';
import { Router } from 'express';
import { PutObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { Types } from 'mongoose';
import { z } from 'zod';
import { PetProfileModel, PhotoAssetModel } from '../db/models';
import { validateBody } from '../middleware/validate';

export const photosRouter = Router();

const uploadPhotoSchema = z.object({
  petId: z.string().optional(),
  fileName: z.string().min(1),
  mimeType: z.string(),
  base64Data: z.string().min(1),
  caption: z.string().optional(),
  date: z.string().optional(),
});

function getRequiredEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required env: ${name}`);
  }
  return value;
}

function getUserObjectId(headerValue: string | undefined) {
  if (!headerValue || !Types.ObjectId.isValid(headerValue)) return null;
  return new Types.ObjectId(headerValue);
}

async function resolvePetForUser(userObjectId: Types.ObjectId, petId?: string) {
  if (petId && Types.ObjectId.isValid(petId)) {
    const existing = await PetProfileModel.findOne({
      _id: new Types.ObjectId(petId),
      ownerUserId: userObjectId,
      archived: false,
    });
    if (existing) return existing;
  }

  const anyPet = await PetProfileModel.findOne({ ownerUserId: userObjectId, archived: false }).sort({ createdAt: 1 });
  if (anyPet) return anyPet;

  return PetProfileModel.create({
    ownerUserId: userObjectId,
    name: 'My Pet',
    species: 'Pet',
    archived: false,
  });
}

function normalizeJpgName(fileName: string) {
  return fileName.toLowerCase().endsWith('.jpg') || fileName.toLowerCase().endsWith('.jpeg')
    ? fileName
    : `${fileName}.jpg`;
}

function createS3Client(region: string) {
  return new S3Client({
    region,
    credentials: {
      accessKeyId: getRequiredEnv('AWS_ACCESS_KEY_ID'),
      secretAccessKey: getRequiredEnv('AWS_SECRET_ACCESS_KEY'),
      sessionToken: process.env.AWS_SESSION_TOKEN,
    },
  });
}

photosRouter.get('/', async (req, res) => {
  try {
    const userObjectId = getUserObjectId(req.header('x-user-id'));
    if (!userObjectId) {
      return res.status(401).json({ error: 'MissingUserId' });
    }

    const pet = await resolvePetForUser(userObjectId, typeof req.query.petId === 'string' ? req.query.petId : undefined);

    const photos = await PhotoAssetModel.find({
      ownerUserId: userObjectId,
      petId: pet._id,
    })
      .sort({ uploadedAt: -1 })
      .limit(800)
      .lean();

    return res.status(200).json({
      pet: {
        id: String(pet._id),
        name: pet.name,
        species: pet.species,
      },
      photos: photos.map((photo) => ({
        id: String(photo._id),
        key: photo.key,
        bucket: photo.bucket,
        region: photo.region,
        fileName: photo.originalFileName || photo.key.split('/').pop() || 'image.jpg',
        caption: photo.caption || '',
        date: new Date(photo.capturedAt || photo.uploadedAt || photo.createdAt).toISOString().slice(0, 10),
        mimeType: photo.mimeType || 'image/jpeg',
        bytes: photo.bytes || 0,
        objectUrl: photo.objectUrl || `https://${photo.bucket}.s3.${photo.region}.amazonaws.com/${photo.key}`,
      })),
    });
  } catch (error: unknown) {
    // eslint-disable-next-line no-console
    console.error('Fetch photos failed:', error);
    return res.status(500).json({ error: 'PhotoFetchFailed' });
  }
});

photosRouter.post('/upload', validateBody(uploadPhotoSchema), async (req, res) => {
  try {
    const userObjectId = getUserObjectId(req.header('x-user-id'));
    if (!userObjectId) {
      return res.status(401).json({ error: 'MissingUserId' });
    }

    const mimeType = req.body.mimeType.toLowerCase();
    if (mimeType !== 'image/jpeg' && mimeType !== 'image/jpg') {
      return res.status(400).json({ error: 'OnlyJpgAllowed' });
    }

    const bucket = getRequiredEnv('S3_BUCKET');
    const region = process.env.S3_REGION || process.env.AWS_DEFAULT_REGION || 'us-west-2';

    const pet = await resolvePetForUser(userObjectId, req.body.petId);
    const safeName = normalizeJpgName(req.body.fileName);
    const objectKey = `pets/${String(userObjectId)}/${String(pet._id)}/${Date.now()}-${randomUUID()}-${safeName}`;

    const bodyBuffer = Buffer.from(req.body.base64Data, 'base64');
    if (!bodyBuffer.length) {
      return res.status(400).json({ error: 'InvalidImageData' });
    }

    const s3 = createS3Client(region);
    await s3.send(
      new PutObjectCommand({
        Bucket: bucket,
        Key: objectKey,
        Body: bodyBuffer,
        ContentType: 'image/jpeg',
      })
    );

    const objectUrl = `https://${bucket}.s3.${region}.amazonaws.com/${objectKey}`;
    const capturedAt = req.body.date ? new Date(req.body.date) : new Date();

    const photo = await PhotoAssetModel.create({
      ownerUserId: userObjectId,
      petId: pet._id,
      bucket,
      key: objectKey,
      region,
      objectUrl,
      originalFileName: safeName,
      mimeType: 'image/jpeg',
      bytes: bodyBuffer.length,
      capturedAt,
      uploadedAt: new Date(),
      caption: req.body.caption || '',
      labels: [],
    });

    return res.status(201).json({
      pet: {
        id: String(pet._id),
        name: pet.name,
        species: pet.species,
      },
      photo: {
        id: String(photo._id),
        key: photo.key,
        bucket: photo.bucket,
        region: photo.region,
        fileName: photo.originalFileName,
        caption: photo.caption || '',
        date: new Date(photo.capturedAt || photo.uploadedAt || photo.createdAt).toISOString().slice(0, 10),
        mimeType: photo.mimeType || 'image/jpeg',
        bytes: photo.bytes || 0,
        objectUrl,
      },
    });
  } catch (error: unknown) {
    // eslint-disable-next-line no-console
    console.error('Upload photo failed:', error);
    return res.status(500).json({ error: 'PhotoUploadFailed' });
  }
});
