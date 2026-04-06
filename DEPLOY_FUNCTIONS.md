# Deploy Cloud Functions - Quick Start

## Prerequisites
- Node.js 18+ installed
- Firebase CLI installed (`npm install -g firebase-tools`)
- Logged into Firebase (`firebase login`)

## Deployment Steps

### 1. Install Dependencies
```bash
cd functions
npm install
```

### 2. Build TypeScript
```bash
npm run build
```

### 3. Deploy Functions
```bash
firebase deploy --only functions
```

Or from the project root:
```bash
firebase deploy --only functions
```

### 4. Verify Deployment
```bash
firebase functions:list
```

You should see `notifyComplaintFixed` in the list.

### 5. View Logs
```bash
firebase functions:log
```

## What the Function Does

When a complaint status is updated to "fixed":
1. Cloud Function triggers automatically
2. Looks up the user's FCM token from Firestore
3. Sends a push notification to their device
4. Notification appears in device notification bar

## Testing

1. **Login as a regular user** and note their email
2. **Switch to admin account**
3. **Open a complaint** from that user
4. **Click "Mark Fixed"**
5. **Check the user's device** - notification should appear in notification bar within 2-3 seconds

## Troubleshooting

### Function not deploying
```bash
npm run build
firebase deploy --only functions --debug
```

### Check function logs
```bash
firebase functions:log --limit 50
```

### Common Issues
- **"No FCM token found"**: User hasn't logged in yet or token wasn't saved
- **"User not found"**: Email in complaint doesn't match user email in database
- **Function not triggering**: Check that complaint document has `userEmail` field

## File Structure
```
functions/
├── src/
│   └── index.ts          (Main Cloud Function)
├── package.json          (Dependencies)
├── tsconfig.json         (TypeScript config)
└── .gitignore           (Git ignore rules)
```

## Next Steps
1. Run `npm install` in functions directory
2. Run `firebase deploy --only functions`
3. Test by marking a complaint as fixed
4. Monitor logs with `firebase functions:log`
