# MongoDB Data Model (Pet Wellness)

This service stores core app data in MongoDB while image binaries remain in S3.

## Collections

- `users`: account/login data with `email` and `passwordHash`.
- `authsessions`: refresh/session token hashes with TTL expiry.
- `petprofiles`: pet profile and medical context.
- `diaryentries`: pet wellness timeline (walks, baths, dental, vet, medication, etc.).
- `photoassets`: S3 metadata only (`bucket`, `key`, `region`, optional URL and dimensions).
- `chatthreads`: chat conversations per pet.
- `chatmessages`: chat messages and optional linked diary suggestion.
- `reminders`: scheduled care reminders.

## Stores exactly what you asked for

- Names of images: `photoassets.originalFileName`, plus S3 location in `photoassets.bucket` + `photoassets.key`.
- Name of pet: `petprofiles.name`.
- All pet diary information: `diaryentries` with type/date/notes/metrics/tags.
- Pet profile: `petprofiles` with species, breed, age fields, vet contacts, allergies, vaccination and medication arrays.
- Login info using email and hashed password: `users.email` + `users.passwordHash`.

## Extra useful data included

- Reminder scheduling (`reminders`) for recurring care.
- Chat-to-diary linkage (`chatmessages.linkedDiaryEntryId`).
- Session tracking with TTL expiration (`authsessions`).
- User accessibility preferences (`users.preferences`) to match frontend settings.

## Quick setup scripts

- Initialize collections and indexes:
  - `npm --prefix services/gateway run db:init`
- Create a login user with hashed password:
  - `npm --prefix services/gateway run db:create-user -- --email=owner@example.com --password=StrongPass123 --name=\"Pet Owner\"`
