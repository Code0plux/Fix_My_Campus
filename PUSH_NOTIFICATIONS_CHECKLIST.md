# Push Notifications Setup Checklist

## ✅ Flutter App Setup (Already Done)

- [x] Added `firebase_messaging` to pubspec.yaml
- [x] Added `flutter_local_notifications` to pubspec.yaml
- [x] Created `NotificationService` class
- [x] Initialized notification service in `main.dart`
- [x] Updated `AuthService` to save FCM tokens
- [x] Removed in-app notification code from complaint detail screen

## ✅ Firebase Cloud Functions Setup (Already Done)

- [x] Created `functions/` directory
- [x] Created `functions/src/index.ts` with notification logic
- [x] Created `functions/package.json` with dependencies
- [x] Created `functions/tsconfig.json` for TypeScript
- [x] Updated `firebase.json` to include functions

## 📋 Next Steps - Deploy Cloud Functions

### Step 1: Install Node.js Dependencies
```bash
cd functions
npm install
```

### Step 2: Build TypeScript
```bash
npm run build
```

### Step 3: Deploy to Firebase
```bash
firebase deploy --only functions
```

### Step 4: Verify Deployment
```bash
firebase functions:list
```

## 🧪 Testing the Push Notifications

### Prerequisites
- App installed on a real device (not emulator for best results)
- User logged in to the app
- Admin account ready

### Test Steps
1. **Login as a regular user**
   - Note their email address
   - App will automatically save their FCM token

2. **Logout and login as admin**
   - Go to Admin Dashboard
   - Find a complaint from the user

3. **Mark complaint as fixed**
   - Open the complaint
   - Click "Mark Fixed" button
   - Status should update to "fixed"

4. **Check user's device**
   - Look at device notification bar
   - Notification should appear: "Complaint Fixed! ✓"
   - Body: "Your complaint has been resolved."

5. **Verify in Firebase Console**
   - Go to Firebase Console → Functions
   - Click `notifyComplaintFixed`
   - Check "Logs" tab for execution details

## 🔍 Troubleshooting

### Notification Not Appearing

**Check 1: FCM Token Saved**
```
Firebase Console → Firestore → users collection
→ Find user document → Check for 'fcmToken' field
```

**Check 2: Function Logs**
```bash
firebase functions:log
```
Look for messages like:
- "Notification sent successfully" ✓
- "No FCM token found" ✗
- "User not found" ✗

**Check 3: Device Permissions**
- Settings → Apps → Your App → Notifications → Enable

**Check 4: Complaint Data**
- Ensure complaint has `userEmail` field
- Ensure email matches user's email in database

### Function Not Deploying

```bash
cd functions
npm run build
firebase deploy --only functions --debug
```

### Function Not Triggering

- Verify complaint document has `userEmail` field
- Check that status field changes from non-"fixed" to "fixed"
- Monitor logs: `firebase functions:log`

## 📱 Device-Specific Setup

### Android
- Ensure `POST_NOTIFICATIONS` permission in AndroidManifest.xml
- Device must have Google Play Services installed
- Notification permissions must be granted in app settings

### iOS
- APNs certificate must be configured in Firebase Console
- Device must have notification permissions enabled
- iOS 13+ recommended

## 📊 Monitoring

### View Function Logs
```bash
firebase functions:log --limit 100
```

### View Recent Executions
```bash
firebase functions:log --limit 50
```

### Real-time Logs
```bash
firebase functions:log
```

## 🚀 Production Checklist

- [ ] Cloud Functions deployed successfully
- [ ] FCM tokens being saved for all users
- [ ] Tested on real Android device
- [ ] Tested on real iOS device (if applicable)
- [ ] Notification permissions granted on test devices
- [ ] Function logs show successful notifications
- [ ] Error handling verified
- [ ] Monitoring set up in Firebase Console

## 📞 Support

If notifications still aren't working:

1. Check Firebase Console → Cloud Functions → Logs
2. Verify user has FCM token in Firestore
3. Ensure complaint has `userEmail` field
4. Check device notification settings
5. Try restarting the app and device

## 🎯 Expected Behavior

**When admin marks complaint as fixed:**
1. Firestore document updates (status → "fixed")
2. Cloud Function triggers automatically (within 1-2 seconds)
3. Function queries user's FCM token
4. Firebase Messaging sends push notification
5. User's device receives notification in notification bar
6. Notification appears even if app is closed

**Notification Content:**
- Title: "Complaint Fixed! ✓"
- Body: "Your complaint has been resolved."
- Data: complaintId, type: "complaint_fixed"
