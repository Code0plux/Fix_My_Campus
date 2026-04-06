# 📋 Code Structure & File Overview

## Complete File Structure

```
fix_my_campus/
├── functions/                          ← Cloud Functions (NEW)
│   ├── src/
│   │   └── index.ts                   ← Main Cloud Function
│   ├── package.json                   ← Dependencies
│   ├── tsconfig.json                  ← TypeScript config
│   └── .gitignore
│
├── lib/
│   ├── services/
│   │   └── notification_service.dart  ← Notification handler (UPDATED)
│   ├── Auth/
│   │   └── auth_service.dart          ← FCM token saving (UPDATED)
│   ├── Screen/
│   │   ├── complaint_detail_screen.dart  ← Status update (UPDATED)
│   │   └── notifications_screen.dart     ← In-app notifications (NEW)
│   └── main.dart                      ← App entry (UPDATED)
│
├── android/
│   └── app/src/main/
│       └── AndroidManifest.xml        ← Permissions (ALREADY SET)
│
├── firebase.json                      ← Functions config (ALREADY SET)
│
└── Documentation/
    ├── PUSH_NOTIFICATIONS_SUMMARY.md  ← Complete overview
    ├── CLOUD_FUNCTIONS_SETUP.md       ← Setup guide
    ├── DEPLOY_FUNCTIONS.md            ← Deployment steps
    ├── PUSH_NOTIFICATIONS_CHECKLIST.md ← Full checklist
    └── QUICK_REFERENCE.md             ← Quick guide
```

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    ADMIN MARKS COMPLAINT FIXED              │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────┐
        │  complaint_detail_screen.dart  │
        │  _updateStatus('fixed')        │
        └────────────────┬───────────────┘
                         │
                         ▼
        ┌────────────────────────────────┐
        │  Firestore: complaints/{id}    │
        │  status: 'fixed'               │
        │  updatedAt: timestamp          │
        └────────────────┬───────────────┘
                         │
                         ▼
        ┌────────────────────────────────┐
        │  Cloud Function Triggers       │
        │  functions/src/index.ts        │
        │  notifyComplaintFixed()        │
        └────────────────┬───────────────┘
                         │
                         ▼
        ┌────────────────────────────────┐
        │  Query Firestore: users        │
        │  Find user by email            │
        │  Get fcmToken                  │
        └────────────────┬───────────────┘
                         │
                         ▼
        ┌────────────────────────────────┐
        │  Firebase Messaging            │
        │  Send Push Notification        │
        └────────────────┬───────────────┘
                         │
                         ▼
        ┌────────────────────────────────┐
        │  User's Device                 │
        │  Notification Bar              │
        │  "Complaint Fixed! ✓"          │
        └────────────────────────────────┘
```

## Key Code Sections

### 1. Cloud Function (functions/src/index.ts)
```typescript
export const notifyComplaintFixed = functions.firestore
  .document("complaints/{complaintId}")
  .onUpdate(async (change, context) => {
    // Triggers when complaint status changes to 'fixed'
    // Sends push notification to user
  });
```

### 2. Notification Service (lib/services/notification_service.dart)
```dart
class NotificationService {
  Future<void> initialize() {
    // Initialize Firebase Messaging
    // Request permissions
    // Handle foreground messages
  }
  
  Future<String?> getFCMToken() {
    // Get device's FCM token
  }
}
```

### 3. Auth Service (lib/Auth/auth_service.dart)
```dart
Future<void> _saveFCMToken(String userId) {
  // Save FCM token to Firestore
  // Called on login/register
}
```

### 4. Complaint Detail Screen (lib/Screen/complaint_detail_screen.dart)
```dart
Future<void> _updateStatus(String newStatus) {
  // Update complaint status in Firestore
  // Cloud Function handles notification
}
```

## Firestore Database Structure

```
users/
  {userId}/
    username: string
    email: string
    isAdmin: boolean
    fcmToken: string          ← Saved by auth_service.dart
    createdAt: timestamp

complaints/
  {complaintId}/
    complaint: string
    userEmail: string         ← Used by Cloud Function
    status: string            ← Triggers Cloud Function
    priority: string
    latitude: number
    longitude: number
    imageUrl: string
    mediaUrl: string
    createdAt: timestamp
    updatedAt: timestamp
```

## Deployment Sequence

```
1. npm install
   └─ Install Node.js dependencies

2. npm run build
   └─ Compile TypeScript to JavaScript

3. firebase deploy --only functions
   └─ Deploy to Firebase Cloud Functions

4. firebase functions:list
   └─ Verify deployment

5. Test on device
   └─ Mark complaint as fixed
   └─ Check notification bar
```

## Environment Setup

### Required Files (Already Created)
- ✅ `functions/src/index.ts`
- ✅ `functions/package.json`
- ✅ `functions/tsconfig.json`
- ✅ `lib/services/notification_service.dart`
- ✅ `lib/Auth/auth_service.dart` (updated)
- ✅ `lib/main.dart` (updated)

### Required Permissions (Already Set)
- ✅ `android:name="android.permission.POST_NOTIFICATIONS"`
- ✅ `android:name="android.permission.INTERNET"`

### Required Dependencies (Already Added)
- ✅ `firebase_messaging` in pubspec.yaml
- ✅ `flutter_local_notifications` in pubspec.yaml
- ✅ `firebase-admin` in functions/package.json
- ✅ `firebase-functions` in functions/package.json

## Testing Checklist

```
Pre-Test:
  ☐ Cloud Functions deployed
  ☐ App built and installed on device
  ☐ Device has internet connection
  ☐ Notification permissions enabled

Test Steps:
  ☐ Login as User A
  ☐ Register a complaint
  ☐ Logout and login as Admin
  ☐ Find User A's complaint
  ☐ Mark as "fixed"
  ☐ Check User A's notification bar
  ☐ Verify notification appears

Post-Test:
  ☐ Check Firebase Console logs
  ☐ Verify FCM token in Firestore
  ☐ Confirm notification content
```

## Common Issues & Solutions

| Issue | File | Solution |
|-------|------|----------|
| Notification not appearing | `functions/src/index.ts` | Check FCM token query |
| Function not deploying | `functions/package.json` | Run `npm install` first |
| FCM token not saving | `lib/Auth/auth_service.dart` | Verify `_saveFCMToken()` called |
| Status update not working | `lib/Screen/complaint_detail_screen.dart` | Check Firestore update |
| Permissions error | `android/app/src/main/AndroidManifest.xml` | Already configured ✓ |

## Next Actions

1. **Deploy Cloud Functions**
   ```bash
   cd functions
   npm install
   firebase deploy --only functions
   ```

2. **Test on Device**
   - Follow testing checklist above

3. **Monitor**
   ```bash
   firebase functions:log
   ```

4. **Troubleshoot**
   - Check logs
   - Verify Firestore data
   - Check device permissions
