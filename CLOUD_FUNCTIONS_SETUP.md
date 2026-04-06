# Firebase Cloud Functions Setup for Push Notifications

## Overview
This guide explains how to set up Firebase Cloud Functions to send push notifications to users' device notification bars when their complaints are marked as fixed.

## Prerequisites
- Firebase CLI installed (`npm install -g firebase-tools`)
- Node.js installed
- Firebase project set up

## Step 1: Initialize Cloud Functions

```bash
cd your_project_root
firebase init functions
```

Choose:
- Language: TypeScript
- ESLint: Yes (optional)

## Step 2: Create the Cloud Function

Replace the contents of `functions/src/index.ts` with:

```typescript
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

export const notifyComplaintFixed = functions.firestore
  .document("complaints/{complaintId}")
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();

    // Check if status changed to 'fixed'
    if (oldData.status !== "fixed" && newData.status === "fixed") {
      const userEmail = newData.userEmail;
      const complaintId = context.params.complaintId;

      try {
        // Get user's FCM token from Firestore
        const userSnapshot = await admin
          .firestore()
          .collection("users")
          .where("email", "==", userEmail)
          .limit(1)
          .get();

        if (!userSnapshot.empty) {
          const fcmToken = userSnapshot.docs[0].data().fcmToken;

          if (fcmToken) {
            // Send push notification
            const message = {
              notification: {
                title: "Complaint Fixed! ✓",
                body: "Your complaint has been resolved.",
              },
              data: {
                complaintId: complaintId,
                type: "complaint_fixed",
              },
              token: fcmToken,
            };

            const response = await admin.messaging().send(message);
            console.log("Notification sent successfully:", response);
          } else {
            console.log("No FCM token found for user:", userEmail);
          }
        } else {
          console.log("User not found:", userEmail);
        }
      } catch (error) {
        console.error("Error sending notification:", error);
      }
    }
  });
```

## Step 3: Update functions/package.json

Ensure your `package.json` has these dependencies:

```json
{
  "name": "functions",
  "description": "Cloud Functions for Firebase",
  "scripts": {
    "build": "tsc",
    "watch": "tsc --watch",
    "serve": "npm run build && firebase emulators:start --only functions",
    "shell": "npm run build && firebase functions:shell",
    "start": "npm run shell",
    "deploy": "firebase deploy --only functions",
    "logs": "firebase functions:log"
  },
  "engines": {
    "node": "18"
  },
  "main": "lib/index.js",
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^4.4.1"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "typescript": "^5.0.0"
  }
}
```

## Step 4: Deploy the Cloud Function

```bash
cd functions
npm install
firebase deploy --only functions
```

## Step 5: Verify Deployment

1. Go to Firebase Console → Functions
2. You should see `notifyComplaintFixed` function listed
3. Check the logs to verify it's working

## How It Works

1. **Trigger**: When a complaint's status is updated to "fixed"
2. **Lookup**: Cloud Function finds the user's FCM token
3. **Send**: Sends a push notification to the device notification bar
4. **Result**: User receives notification even if app is closed

## Testing

### Test via Firebase Console
1. Go to Firebase Console → Cloud Messaging
2. Create a new campaign
3. Select your app
4. Send a test notification

### Test via Admin Dashboard
1. Open a complaint in the admin dashboard
2. Click "Mark Fixed"
3. Check the user's device notification bar
4. Notification should appear within seconds

## Troubleshooting

### Function Not Triggering
- Check Cloud Functions logs: `firebase functions:log`
- Verify complaint document has `userEmail` field
- Ensure status field exists in complaint

### Notification Not Received
- Verify FCM token is saved in user document
- Check user's notification permissions on device
- Verify device has internet connection
- Check Firebase Console → Cloud Messaging for errors

### FCM Token Issues
- Ensure user is logged in when app starts
- Check that `NotificationService().initialize()` is called in main.dart
- Verify token is being saved to Firestore

## Production Checklist

- [ ] Cloud Function deployed
- [ ] FCM tokens being saved for all users
- [ ] Tested on actual devices (not just emulator)
- [ ] Notification permissions granted on devices
- [ ] Error handling in place
- [ ] Monitoring enabled in Firebase Console

## Next Steps

1. Deploy the Cloud Function
2. Test by marking a complaint as fixed
3. Verify notification appears on user's device
4. Monitor logs for any errors
