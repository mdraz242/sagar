# Firebase Setup

1. Create a Firebase project and add Android app id `com.vyparhub.mobile`.
2. Download `google-services.json` into `mobile/android/app/google-services.json`.
3. Enable Firebase Cloud Messaging, Analytics, and Crashlytics.
4. Put Firebase Admin service-account values in `server/.env`:

```env
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-...@your-project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

5. After login, the Flutter app registers the device FCM token through `PUT /api/profile`.
6. Foreground messages are shown through `flutter_local_notifications`.

The Flutter app initializes Firebase defensively so local demos can open before Firebase files are added.
