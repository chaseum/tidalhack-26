// MongoDB Playground seed data for pet_wellness
// Run this with MongoDB VS Code extension "Run Playground".

use('pet_wellness');

const seedTag = 'seed_v1';
const now = new Date();

// Fixed IDs keep references stable and make reruns deterministic.
const owner1 = ObjectId('67a69e4a0f00000000000001');
const owner2 = ObjectId('67a69e4a0f00000000000002');

const pet1 = ObjectId('67a69e4a0f00000000000101');
const pet2 = ObjectId('67a69e4a0f00000000000102');

const thread1 = ObjectId('67a69e4a0f00000000000201');
const thread2 = ObjectId('67a69e4a0f00000000000202');

const diary1 = ObjectId('67a69e4a0f00000000000301');
const diary2 = ObjectId('67a69e4a0f00000000000302');
const diary3 = ObjectId('67a69e4a0f00000000000303');
const diary4 = ObjectId('67a69e4a0f00000000000304');

const photo1 = ObjectId('67a69e4a0f00000000000401');
const photo2 = ObjectId('67a69e4a0f00000000000402');
const photo3 = ObjectId('67a69e4a0f00000000000403');

const msg1 = ObjectId('67a69e4a0f00000000000501');
const msg2 = ObjectId('67a69e4a0f00000000000502');
const msg3 = ObjectId('67a69e4a0f00000000000503');
const msg4 = ObjectId('67a69e4a0f00000000000504');

const reminder1 = ObjectId('67a69e4a0f00000000000601');
const reminder2 = ObjectId('67a69e4a0f00000000000602');
const reminder3 = ObjectId('67a69e4a0f00000000000603');

const session1 = ObjectId('67a69e4a0f00000000000701');

// Cleanup prior seed run
for (const collection of [
  'users',
  'petprofiles',
  'diaryentries',
  'photoassets',
  'chatthreads',
  'chatmessages',
  'reminders',
  'authsessions',
]) {
  db.getCollection(collection).deleteMany({ seedTag });
}

// Users (passwordHash values are sample bcrypt hashes)
db.users.insertMany([
  {
    _id: owner1,
    seedTag,
    email: 'owner1@example.com',
    passwordHash: '$2a$12$8qXW3.1mFx1D7Yk9YwGJ5uNQO8HQ4DqX5A6Qf2P9a2N6k2qQ0s6x2',
    displayName: 'Blake Harris',
    isEmailVerified: true,
    roles: ['owner'],
    lastLoginAt: now,
    loginCount: 18,
    preferences: {
      theme: 'sunrise',
      fontScale: 1.1,
      dyslexiaFont: false,
      timeZone: 'America/Chicago',
    },
    createdAt: now,
    updatedAt: now,
  },
  {
    _id: owner2,
    seedTag,
    email: 'owner2@example.com',
    passwordHash: '$2a$12$W1Qx8V6NdL5dBnQ1GvCjUeP5s3WmPd2s3LrGZ1cYf8sB6m4Hq9k5m',
    displayName: 'Jordan Lee',
    isEmailVerified: false,
    roles: ['owner'],
    lastLoginAt: now,
    loginCount: 3,
    preferences: {
      theme: 'forest',
      fontScale: 1,
      dyslexiaFont: true,
      timeZone: 'America/Los_Angeles',
    },
    createdAt: now,
    updatedAt: now,
  },
]);

// Pet profiles
db.petprofiles.insertMany([
  {
    _id: pet1,
    seedTag,
    ownerUserId: owner1,
    name: 'Mochi',
    species: 'Cat',
    breed: 'Domestic Shorthair',
    sex: 'female',
    birthDate: new Date('2022-06-01'),
    weightKg: 4.4,
    allergies: ['Chicken protein'],
    medications: [{ name: 'Omega-3', dosage: '1 capsule', schedule: 'daily' }],
    vaccinationRecords: [
      { vaccine: 'Rabies', date: new Date('2025-05-10'), nextDueDate: new Date('2026-05-10') },
    ],
    vetContacts: { primaryClinic: 'Green Valley Vet', phone: '555-0101' },
    avatarImageS3Key: 'pets/mochi/profile.jpg',
    notes: 'Indoor cat, very food-motivated.',
    archived: false,
    createdAt: now,
    updatedAt: now,
  },
  {
    _id: pet2,
    seedTag,
    ownerUserId: owner2,
    name: 'Rex',
    species: 'Dog',
    breed: 'Golden Retriever',
    sex: 'male',
    birthDate: new Date('2021-09-14'),
    weightKg: 29.8,
    allergies: [],
    medications: [],
    vaccinationRecords: [
      { vaccine: 'DHPP', date: new Date('2025-03-12'), nextDueDate: new Date('2026-03-12') },
    ],
    vetContacts: { primaryClinic: 'Westside Animal Care', phone: '555-0102' },
    avatarImageS3Key: 'pets/rex/profile.jpg',
    notes: 'High energy, likes long walks.',
    archived: false,
    createdAt: now,
    updatedAt: now,
  },
]);

// Photo metadata (S3 references)
db.photoassets.insertMany([
  {
    _id: photo1,
    seedTag,
    ownerUserId: owner1,
    petId: pet1,
    bucket: 'tidal-user-information',
    key: 'IMG_0265.jpg',
    region: 'us-west-2',
    objectUrl: 'https://tidal-user-information.s3.us-west-2.amazonaws.com/IMG_0265.jpg',
    originalFileName: 'IMG_0265.jpg',
    mimeType: 'image/jpeg',
    bytes: 284001,
    width: 2048,
    height: 1536,
    capturedAt: new Date('2026-02-05T12:30:00Z'),
    uploadedAt: now,
    caption: 'Post-grooming photo',
    labels: ['groomed', 'healthy-coat'],
    isFavorite: true,
    createdAt: now,
    updatedAt: now,
  },
  {
    _id: photo2,
    seedTag,
    ownerUserId: owner1,
    petId: pet1,
    bucket: 'tidal-user-information',
    key: 'pets/mochi/walk-park.jpg',
    region: 'us-west-2',
    originalFileName: 'walk-park.jpg',
    mimeType: 'image/jpeg',
    bytes: 198220,
    uploadedAt: now,
    caption: 'Morning park walk',
    labels: ['walk'],
    isFavorite: false,
    createdAt: now,
    updatedAt: now,
  },
  {
    _id: photo3,
    seedTag,
    ownerUserId: owner2,
    petId: pet2,
    bucket: 'tidal-user-information',
    key: 'pets/rex/vet-check.jpg',
    region: 'us-west-2',
    originalFileName: 'vet-check.jpg',
    mimeType: 'image/jpeg',
    bytes: 164002,
    uploadedAt: now,
    caption: 'Annual vet visit',
    labels: ['vet'],
    isFavorite: false,
    createdAt: now,
    updatedAt: now,
  },
]);

// Diary entries
db.diaryentries.insertMany([
  {
    _id: diary1,
    seedTag,
    ownerUserId: owner1,
    petId: pet1,
    type: 'Walk',
    happenedAt: new Date('2026-02-07T16:00:00Z'),
    durationMinutes: 28,
    notes: 'Brisk neighborhood loop, good energy and appetite after.',
    tags: ['exercise'],
    metrics: { moodScore: 4, appetiteScore: 5 },
    source: 'manual',
    relatedPhotoIds: [photo2],
    createdAt: now,
    updatedAt: now,
  },
  {
    _id: diary2,
    seedTag,
    ownerUserId: owner1,
    petId: pet1,
    type: 'Dental Cleaning',
    happenedAt: new Date('2026-02-06T21:00:00Z'),
    notes: 'Used enzymatic toothpaste, tolerated well.',
    tags: ['dental'],
    metrics: {},
    source: 'manual',
    relatedPhotoIds: [],
    createdAt: now,
    updatedAt: now,
  },
  {
    _id: diary3,
    seedTag,
    ownerUserId: owner2,
    petId: pet2,
    type: 'Vet Visit',
    happenedAt: new Date('2026-02-01T17:30:00Z'),
    notes: 'Annual check-up completed, no issues.',
    tags: ['preventive-care'],
    metrics: { weightKg: 29.8 },
    source: 'manual',
    relatedPhotoIds: [photo3],
    createdAt: now,
    updatedAt: now,
  },
  {
    _id: diary4,
    seedTag,
    ownerUserId: owner1,
    petId: pet1,
    type: 'Bath',
    happenedAt: new Date('2026-02-05T14:00:00Z'),
    notes: 'Hypoallergenic shampoo, coat condition improved.',
    tags: ['grooming'],
    source: 'manual',
    relatedPhotoIds: [photo1],
    createdAt: now,
    updatedAt: now,
  },
]);

// Chat threads
db.chatthreads.insertMany([
  {
    _id: thread1,
    seedTag,
    ownerUserId: owner1,
    petId: pet1,
    title: 'Mochi Wellness Questions',
    archived: false,
    createdAt: now,
    updatedAt: now,
  },
  {
    _id: thread2,
    seedTag,
    ownerUserId: owner2,
    petId: pet2,
    title: 'Rex Routine Planning',
    archived: false,
    createdAt: now,
    updatedAt: now,
  },
]);

// Chat messages
db.chatmessages.insertMany([
  {
    _id: msg1,
    seedTag,
    threadId: thread1,
    ownerUserId: owner1,
    petId: pet1,
    role: 'user',
    content: 'Mochi has been scratching more. What should I track?',
    createdAt: now,
    updatedAt: now,
  },
  {
    _id: msg2,
    seedTag,
    threadId: thread1,
    ownerUserId: owner1,
    petId: pet1,
    role: 'assistant',
    content: 'Track scratching frequency, skin redness, and bath products for 3 days.',
    suggestedDiaryEntry: {
      type: 'Symptom',
      notes: 'Monitor scratching frequency and skin redness daily for 3 days.',
      happenedAt: now,
    },
    linkedDiaryEntryId: diary4,
    createdAt: now,
    updatedAt: now,
  },
  {
    _id: msg3,
    seedTag,
    threadId: thread2,
    ownerUserId: owner2,
    petId: pet2,
    role: 'user',
    content: 'Can you suggest a weekly walk routine for Rex?',
    createdAt: now,
    updatedAt: now,
  },
  {
    _id: msg4,
    seedTag,
    threadId: thread2,
    ownerUserId: owner2,
    petId: pet2,
    role: 'assistant',
    content: 'Aim for 2 longer walks and 3 shorter enrichment walks each week.',
    suggestedDiaryEntry: {
      type: 'Walk',
      notes: 'Adopted recommended weekly walk cadence from chat assistant.',
      happenedAt: now,
    },
    createdAt: now,
    updatedAt: now,
  },
]);

// Reminders
db.reminders.insertMany([
  {
    _id: reminder1,
    seedTag,
    ownerUserId: owner1,
    petId: pet1,
    type: 'Dental Cleaning',
    title: 'Brush Mochi teeth',
    description: 'Evening brushing routine',
    dueAt: new Date('2026-02-09T02:00:00Z'),
    recurrence: 'daily',
    status: 'pending',
    createdAt: now,
    updatedAt: now,
  },
  {
    _id: reminder2,
    seedTag,
    ownerUserId: owner1,
    petId: pet1,
    type: 'Vet Visit',
    title: 'Annual wellness exam',
    description: 'Book for May',
    dueAt: new Date('2026-05-01T15:00:00Z'),
    recurrence: 'none',
    status: 'pending',
    createdAt: now,
    updatedAt: now,
  },
  {
    _id: reminder3,
    seedTag,
    ownerUserId: owner2,
    petId: pet2,
    type: 'Walk',
    title: 'Evening park walk',
    dueAt: new Date('2026-02-08T23:30:00Z'),
    recurrence: 'daily',
    status: 'pending',
    createdAt: now,
    updatedAt: now,
  },
]);

// Auth sessions
db.authsessions.insertMany([
  {
    _id: session1,
    seedTag,
    userId: owner1,
    refreshTokenHash: '$2a$12$Wf1hDUmT8mQ3BQhQek9Vte4fDFvXTa3F0A2oJexWQJvM4NUY2uHha',
    userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X)',
    ipAddress: '203.0.113.10',
    expiresAt: new Date(Date.now() + 1000 * 60 * 60 * 24 * 7),
    revokedAt: null,
    createdAt: now,
    updatedAt: now,
  },
]);

print('Seed complete. Documents inserted with seedTag:', seedTag);
print('users:', db.users.countDocuments({ seedTag }));
print('petprofiles:', db.petprofiles.countDocuments({ seedTag }));
print('diaryentries:', db.diaryentries.countDocuments({ seedTag }));
print('photoassets:', db.photoassets.countDocuments({ seedTag }));
print('chatthreads:', db.chatthreads.countDocuments({ seedTag }));
print('chatmessages:', db.chatmessages.countDocuments({ seedTag }));
print('reminders:', db.reminders.countDocuments({ seedTag }));
print('authsessions:', db.authsessions.countDocuments({ seedTag }));
