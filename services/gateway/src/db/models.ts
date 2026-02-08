import { Schema, model, models } from 'mongoose';

const objectId = Schema.Types.ObjectId;

const userSchema = new Schema(
  {
    email: { type: String, required: true, lowercase: true, trim: true },
    passwordHash: { type: String, required: true },
    displayName: { type: String, trim: true },
    isEmailVerified: { type: Boolean, default: false },
    roles: { type: [String], default: ['owner'] },
    lastLoginAt: { type: Date },
    loginCount: { type: Number, default: 0 },
    authProviders: {
      type: [
        new Schema(
          {
            provider: { type: String, required: true },
            providerUserId: { type: String, required: true },
          },
          { _id: false }
        ),
      ],
      default: [],
    },
    preferences: {
      theme: { type: String, default: 'sunrise' },
      fontScale: { type: Number, default: 1 },
      dyslexiaFont: { type: Boolean, default: false },
      timeZone: { type: String, default: 'UTC' },
    },
  },
  { timestamps: true }
);

userSchema.index({ email: 1 }, { unique: true });

const petProfileSchema = new Schema(
  {
    ownerUserId: { type: objectId, ref: 'User', required: true, index: true },
    name: { type: String, required: true, trim: true },
    species: { type: String, required: true, trim: true },
    breed: { type: String, trim: true },
    sex: { type: String, enum: ['female', 'male', 'unknown'], default: 'unknown' },
    birthDate: { type: Date },
    weightKg: { type: Number },
    microchipId: { type: String, trim: true },
    allergies: { type: [String], default: [] },
    medications: {
      type: [
        new Schema(
          {
            name: { type: String, required: true },
            dosage: { type: String },
            schedule: { type: String },
            startedAt: { type: Date },
            endedAt: { type: Date },
          },
          { _id: false }
        ),
      ],
      default: [],
    },
    vaccinationRecords: {
      type: [
        new Schema(
          {
            vaccine: { type: String, required: true },
            date: { type: Date, required: true },
            nextDueDate: { type: Date },
            provider: { type: String },
            notes: { type: String },
          },
          { _id: false }
        ),
      ],
      default: [],
    },
    vetContacts: {
      primaryClinic: { type: String },
      vetName: { type: String },
      phone: { type: String },
      emergencyPhone: { type: String },
    },
    insurance: {
      provider: { type: String },
      policyNumber: { type: String },
    },
    avatarImageS3Key: { type: String },
    notes: { type: String },
    archived: { type: Boolean, default: false },
  },
  { timestamps: true }
);

petProfileSchema.index({ ownerUserId: 1, name: 1 });

const diaryEntrySchema = new Schema(
  {
    ownerUserId: { type: objectId, ref: 'User', required: true, index: true },
    petId: { type: objectId, ref: 'PetProfile', required: true, index: true },
    type: {
      type: String,
      required: true,
      enum: [
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
      ],
    },
    happenedAt: { type: Date, required: true, index: true },
    durationMinutes: { type: Number },
    notes: { type: String, required: true },
    tags: { type: [String], default: [] },
    metrics: {
      weightKg: { type: Number },
      temperatureC: { type: Number },
      appetiteScore: { type: Number },
      moodScore: { type: Number },
      stoolQualityScore: { type: Number },
    },
    source: {
      type: String,
      enum: ['manual', 'chat_assistant', 'import'],
      default: 'manual',
    },
    linkedChatMessageId: { type: objectId, ref: 'ChatMessage' },
    relatedPhotoIds: { type: [objectId], ref: 'PhotoAsset', default: [] },
  },
  { timestamps: true }
);

diaryEntrySchema.index({ petId: 1, happenedAt: -1 });
diaryEntrySchema.index({ ownerUserId: 1, petId: 1, type: 1, happenedAt: -1 });

const photoAssetSchema = new Schema(
  {
    ownerUserId: { type: objectId, ref: 'User', required: true, index: true },
    petId: { type: objectId, ref: 'PetProfile', required: true, index: true },
    bucket: { type: String, required: true },
    key: { type: String, required: true },
    region: { type: String, required: true },
    objectUrl: { type: String },
    originalFileName: { type: String },
    mimeType: { type: String, default: 'image/jpeg' },
    bytes: { type: Number },
    width: { type: Number },
    height: { type: Number },
    capturedAt: { type: Date },
    uploadedAt: { type: Date, default: Date.now, index: true },
    caption: { type: String },
    labels: { type: [String], default: [] },
    isFavorite: { type: Boolean, default: false },
  },
  { timestamps: true }
);

photoAssetSchema.index({ bucket: 1, key: 1 }, { unique: true });
photoAssetSchema.index({ petId: 1, uploadedAt: -1 });

const chatThreadSchema = new Schema(
  {
    ownerUserId: { type: objectId, ref: 'User', required: true, index: true },
    petId: { type: objectId, ref: 'PetProfile', required: true, index: true },
    title: { type: String, default: 'Health Chat' },
    archived: { type: Boolean, default: false },
  },
  { timestamps: true }
);

chatThreadSchema.index({ ownerUserId: 1, petId: 1, updatedAt: -1 });

const chatMessageSchema = new Schema(
  {
    threadId: { type: objectId, ref: 'ChatThread', required: true, index: true },
    ownerUserId: { type: objectId, ref: 'User', required: true, index: true },
    petId: { type: objectId, ref: 'PetProfile', required: true, index: true },
    role: { type: String, enum: ['user', 'assistant', 'system'], required: true },
    content: { type: String, required: true },
    suggestedDiaryEntry: {
      type: new Schema(
        {
          type: { type: String },
          notes: { type: String },
          happenedAt: { type: Date },
        },
        { _id: false }
      ),
      default: undefined,
    },
    linkedDiaryEntryId: { type: objectId, ref: 'DiaryEntry' },
  },
  { timestamps: true }
);

chatMessageSchema.index({ threadId: 1, createdAt: 1 });

const reminderSchema = new Schema(
  {
    ownerUserId: { type: objectId, ref: 'User', required: true, index: true },
    petId: { type: objectId, ref: 'PetProfile', required: true, index: true },
    type: {
      type: String,
      enum: ['Walk', 'Bath', 'Dental Cleaning', 'Vet Visit', 'Medication', 'Vaccination', 'Other'],
      required: true,
    },
    title: { type: String, required: true },
    description: { type: String },
    dueAt: { type: Date, required: true, index: true },
    recurrence: {
      type: String,
      enum: ['none', 'daily', 'weekly', 'monthly'],
      default: 'none',
    },
    status: { type: String, enum: ['pending', 'completed', 'dismissed'], default: 'pending' },
    completedAt: { type: Date },
  },
  { timestamps: true }
);

reminderSchema.index({ ownerUserId: 1, petId: 1, dueAt: 1, status: 1 });

const authSessionSchema = new Schema(
  {
    userId: { type: objectId, ref: 'User', required: true, index: true },
    refreshTokenHash: { type: String, required: true },
    userAgent: { type: String },
    ipAddress: { type: String },
    expiresAt: { type: Date, required: true },
    revokedAt: { type: Date },
  },
  { timestamps: true }
);

authSessionSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

authSessionSchema.index({ userId: 1, createdAt: -1 });

export const UserModel = models.User ?? model('User', userSchema);
export const PetProfileModel = models.PetProfile ?? model('PetProfile', petProfileSchema);
export const DiaryEntryModel = models.DiaryEntry ?? model('DiaryEntry', diaryEntrySchema);
export const PhotoAssetModel = models.PhotoAsset ?? model('PhotoAsset', photoAssetSchema);
export const ChatThreadModel = models.ChatThread ?? model('ChatThread', chatThreadSchema);
export const ChatMessageModel = models.ChatMessage ?? model('ChatMessage', chatMessageSchema);
export const ReminderModel = models.Reminder ?? model('Reminder', reminderSchema);
export const AuthSessionModel = models.AuthSession ?? model('AuthSession', authSessionSchema);

export const allModels = [
  UserModel,
  PetProfileModel,
  DiaryEntryModel,
  PhotoAssetModel,
  ChatThreadModel,
  ChatMessageModel,
  ReminderModel,
  AuthSessionModel,
];
