import { Router } from 'express';
import { Types } from 'mongoose';
import { z } from 'zod';
import { DiaryEntryModel, PetProfileModel } from '../db/models';
import { getUserObjectId, requireUserId } from '../middleware/auth';
import { validateBody } from '../middleware/validate';

export const diaryRouter = Router();
diaryRouter.use(requireUserId);

const diaryTypes = [
  'Walk',
  'Bath',
  'Dental Cleaning',
  'Vet Visit',
  'Medication',
  'Nutrition',
  'Grooming',
  'Symptom',
  'Behavior',
  'Vaccination',
  'Other',
] as const;

const createDiaryEntrySchema = z.object({
  petId: z.string().optional(),
  type: z.enum(diaryTypes),
  date: z.string().optional(),
  notes: z.string().min(1),
  durationMinutes: z.number().int().positive().optional(),
  tags: z.array(z.string()).optional(),
});

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

diaryRouter.get('/', async (req, res) => {
  try {
    const userObjectId = getUserObjectId(res);

    const petId = typeof req.query.petId === 'string' ? req.query.petId : undefined;
    const pet = await resolvePetForUser(userObjectId, petId);

    const entries = await DiaryEntryModel.find({
      ownerUserId: userObjectId,
      petId: pet._id,
    })
      .sort({ happenedAt: -1 })
      .limit(500)
      .lean();

    return res.status(200).json({
      pet: {
        id: String(pet._id),
        name: pet.name,
        species: pet.species,
      },
      entries: entries.map((entry) => ({
        id: String(entry._id),
        type: entry.type,
        date: new Date(entry.happenedAt).toISOString().slice(0, 10),
        notes: entry.notes,
        durationMinutes: entry.durationMinutes ?? null,
        tags: entry.tags ?? [],
      })),
    });
  } catch (error: unknown) {
    // eslint-disable-next-line no-console
    console.error('Fetch diary failed:', error);
    return res.status(500).json({ error: 'DiaryFetchFailed' });
  }
});

diaryRouter.post('/', validateBody(createDiaryEntrySchema), async (req, res) => {
  try {
    const userObjectId = getUserObjectId(res);

    const pet = await resolvePetForUser(userObjectId, req.body.petId);
    const happenedAt = req.body.date ? new Date(req.body.date) : new Date();

    const entry = await DiaryEntryModel.create({
      ownerUserId: userObjectId,
      petId: pet._id,
      type: req.body.type,
      happenedAt,
      durationMinutes: req.body.durationMinutes,
      notes: req.body.notes,
      tags: req.body.tags ?? [],
      source: 'manual',
    });

    return res.status(201).json({
      pet: {
        id: String(pet._id),
        name: pet.name,
        species: pet.species,
      },
      entry: {
        id: String(entry._id),
        type: entry.type,
        date: new Date(entry.happenedAt).toISOString().slice(0, 10),
        notes: entry.notes,
        durationMinutes: entry.durationMinutes ?? null,
        tags: entry.tags ?? [],
      },
    });
  } catch (error: unknown) {
    // eslint-disable-next-line no-console
    console.error('Create diary entry failed:', error);
    return res.status(500).json({ error: 'DiaryCreateFailed' });
  }
});
