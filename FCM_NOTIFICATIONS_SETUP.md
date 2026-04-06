# Firebase Cloud Messaging Setup for Notifications

## Overview
This guide explains how to set up Firebase Cloud Messaging (FCM) to send push notifications when complaints are marked as fixed.

## What's Been Implemented

1. **NotificationService** (`lib/services/notification_service.dart`)
   - Handles local notifications using `flutter_local_notifications`
   - Manages FCM token retrieval and storage
   - Sends local notifications when complaints are marked as fixed

2. **Auth Service Updates** (`lib/Auth/auth_service.dart`)
   - Automatically saves FCM tokens to Firestore when users login/register
   - Tokens are stored in the `users` collection under `fcmToken` field

3. **Complaint Detail Screen Updates** (`lib/Screen/complaint_detail_screen.dart`)
   - Triggers notification when admin marks complaint as "fixed"
   - Sends notification to the complaint creator

## How Notifications Work

### Current Implementation (Local Notifications)
- When a complaint is marked as fixed, a local notification is shown on the admin's device
- The user who filed the complaint will receive a notification when they open the app next

### For Remote Push Notifications (Recommended for Production)
To send push notifications to users even when the app is closed, you need to implement a backend service:

#### Option 1: Firebase Cloud Functions (Recommended)
Create a Cloud Function that sends notifications when complaint status changes:

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

exports.notifyComplaintFixed = functions.firestore
  .document('complaints/{complaintId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();
    
    // Check if status changed to 'fixed'
    if (oldData.status !== 'fixed' && newData.status === 'fixed') {
      const userEmail = newData.userEmail;
      
      // Get user's FCM token
      const userSnapshot = await admin.firestore()
        .collection('users')
        .where('email', '==', userEmail)
        .limit(1)
        .get();
      
      if (!userSnapshot.empty) {
        const fcmToken = userSnapshot.docs[0].data().fcmToken;
        
        if (fcmToken) {
          // Send notification
          await admin.messaging().send({
            notification: {
              title: 'Complaint Fixed!',
              body: 'Your complaint has been resolved.',
            },
            data: {
              complaintId: context.params.complaintId,
              type: 'complaint_fixed',
            },
            token: fcmToken,
          });
        }
      }
    }
  });
```

#### Option 2: Custom Backend Server
Implement a REST API endpoint that:
1. Receives complaint status updates
2. Queries Firestore for user FCM tokens
3. Sends notifications via Firebase Admin SDK

## Android Setup

### 1. Add Google Services Configuration
- Ensure `android/app/google-services.json` is present (already configured)

### 2. Update Android Manifest
Edit `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest ...>
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    
    <application ...>
        <!-- Your existing configuration -->
    </application>
</manifest>
```

### 3. Update build.gradle
Ensure `android/app/build.gradle` has:

```gradle
dependencies {
    implementation 'com.google.firebase:firebase-messaging'
}
```

## iOS Setup

### 1. Enable Push Notifications
- Open `ios/Runner.xcworkspace` in Xcode
- Select Runner project → Runner target
- Go to Signing & Capabilities
- Click "+ Capability" and add "Push Notifications"

### 2. Configure APNs Certificate
- Go to Apple Developer Portal
- Create an APNs certificate for your app
- Upload it to Firebase Console under Project Settings → Cloud Messaging

## Firestore Database Structure

Ensure your `users` collection has this structure:

```
users/
  {userId}/
    username: string
    email: string
    isAdmin: boolean
    fcmToken: string (auto-populated)
    createdAt: timestamp
```

## Testing Notifications

### Local Testing
1. Run the app on a device/emulator
2. Login/Register to save FCM token
3. Go to Admin Dashboard
4. Open a complaint and mark it as "fixed"
5. You should see a local notification

### Firebase Console Testing
1. Go to Firebase Console → Cloud Messaging
2. Create a new campaign
3. Select your app
4. Send a test notification to verify setup

## Troubleshooting

### Notifications Not Appearing
- Check that FCM token is saved in Firestore: `users/{userId}/fcmToken`
- Verify notification permissions are granted on the device
- Check logcat/console for error messages

### FCM Token Not Saving
- Ensure `NotificationService().initialize()` is called in `main()`
- Check that user document exists in Firestore before updating

### Android Specific
- Ensure `POST_NOTIFICATIONS` permission is granted
- Check that Google Play Services is installed on the device

## Production Considerations

1. **Notification Channels**: Already configured for Android with channel ID `complaint_channel`
2. **Permissions**: Request notification permissions on app startup
3. **Token Refresh**: FCM tokens are automatically refreshed by Firebase
4. **Error Handling**: All notification operations have try-catch blocks

## Next Steps

1. Configure APNs certificate for iOS (if deploying to iOS)
2. Test notifications on actual devices
3. Monitor notification delivery in Firebase Console
4. Customize notification content as needed
