// MongoDB Playground script to initialize the pet_wellness database
// Run this in the MongoDB VS Code extension while connected to your Atlas cluster.

use('pet_wellness');

// Explicitly create collections (safe if they already exist)
for (const name of [
  'users',
  'petprofiles',
  'diaryentries',
  'photoassets',
  'chatthreads',
  'chatmessages',
  'reminders',
  'authsessions',
]) {
  if (!db.getCollectionNames().includes(name)) {
    db.createCollection(name);
  }
}

// users
 db.users.createIndex({ email: 1 }, { unique: true, name: 'email_unique' });

// petprofiles
 db.petprofiles.createIndex({ ownerUserId: 1, name: 1 }, { name: 'owner_name' });

// diaryentries
 db.diaryentries.createIndex({ petId: 1, happenedAt: -1 }, { name: 'pet_happenedAt_desc' });
 db.diaryentries.createIndex(
  { ownerUserId: 1, petId: 1, type: 1, happenedAt: -1 },
  { name: 'owner_pet_type_happenedAt_desc' }
);

// photoassets
 db.photoassets.createIndex({ bucket: 1, key: 1 }, { unique: true, name: 'bucket_key_unique' });
 db.photoassets.createIndex({ petId: 1, uploadedAt: -1 }, { name: 'pet_uploadedAt_desc' });

// chatthreads
 db.chatthreads.createIndex({ ownerUserId: 1, petId: 1, updatedAt: -1 }, { name: 'owner_pet_updatedAt_desc' });

// chatmessages
 db.chatmessages.createIndex({ threadId: 1, createdAt: 1 }, { name: 'thread_createdAt_asc' });

// reminders
 db.reminders.createIndex(
  { ownerUserId: 1, petId: 1, dueAt: 1, status: 1 },
  { name: 'owner_pet_dueAt_status' }
);

// authsessions
 db.authsessions.createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0, name: 'expiresAt_ttl' });
 db.authsessions.createIndex({ userId: 1, createdAt: -1 }, { name: 'user_createdAt_desc' });

// Optional sanity check output
print('Initialized collections:', db.getCollectionNames().join(', '));
print('users indexes:', tojson(db.users.getIndexes()));
print('photoassets indexes:', tojson(db.photoassets.getIndexes()));
print('authsessions indexes:', tojson(db.authsessions.getIndexes()));
