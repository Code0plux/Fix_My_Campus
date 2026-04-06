# 🚀 Quick Reference - Push Notifications

## Deploy in 3 Steps

```bash
# Step 1: Install dependencies
cd functions
npm install

# Step 2: Deploy
firebase deploy --only functions

# Step 3: Verify
firebase functions:list
```

## Test in 5 Steps

1. **Login as User A** → App saves FCM token
2. **Register a complaint** → Note the complaint
3. **Logout → Login as Admin** → Go to Admin Dashboard
4. **Mark complaint as fixed** → Click "Mark Fixed"
5. **Check User A's device** → Notification appears in notification bar

## File Locations

```
functions/
├── src/index.ts          ← Cloud Function code
├── package.json          ← Dependencies
└── tsconfig.json         ← TypeScript config

lib/
├── services/notification_service.dart    ← Notification handler
└── Auth/auth_service.dart                ← FCM token saving
```

## Notification Content

**Title:** Complaint Fixed! ✓
**Body:** Your complaint has been resolved.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Notification not appearing | Check FCM token in Firestore |
| Function not deploying | Run `npm run build` first |
| Function not triggering | Verify complaint has `userEmail` field |
| No logs | Run `firebase functions:log` |

## Key Commands

```bash
# Deploy functions
firebase deploy --only functions

# View logs
firebase functions:log

# List functions
firebase functions:list

# Build TypeScript
npm run build

# Install dependencies
npm install
```

## Checklist

- [ ] Run `npm install` in functions directory
- [ ] Run `firebase deploy --only functions`
- [ ] Verify: `firebase functions:list`
- [ ] Test on real device
- [ ] Check logs: `firebase functions:log`

## Documentation Files

- `PUSH_NOTIFICATIONS_SUMMARY.md` - Complete overview
- `CLOUD_FUNCTIONS_SETUP.md` - Detailed setup guide
- `DEPLOY_FUNCTIONS.md` - Deployment instructions
- `PUSH_NOTIFICATIONS_CHECKLIST.md` - Full checklist

---

**Ready to deploy?** Start with: `cd functions && npm install && firebase deploy --only functions`
