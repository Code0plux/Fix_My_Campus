# 🎯 Step-by-Step Commands

## Phase 1: Deploy Cloud Functions

### Command 1: Navigate to functions directory
```bash
cd functions
```

### Command 2: Install dependencies
```bash
npm install
```
**Expected output:** Should show "added X packages"

### Command 3: Build TypeScript
```bash
npm run build
```
**Expected output:** Should compile without errors

### Command 4: Deploy to Firebase
```bash
firebase deploy --only functions
```
**Expected output:** Should show "✔ functions deployed successfully"

### Command 5: Verify deployment
```bash
firebase functions:list
```
**Expected output:** Should show `notifyComplaintFixed` in the list

### Command 6: View logs (optional)
```bash
firebase functions:log
```
**Expected output:** Should show function execution logs

---

## Phase 2: Test on Device

### Step 1: Build and run the Flutter app
```bash
flutter pub get
flutter run
```

### Step 2: Login as User A
- Open the app
- Go to Login screen
- Enter User A's email and password
- App automatically saves FCM token

### Step 3: Register a complaint
- Click on "Register Complaint" or similar button
- Fill in complaint details
- Submit the complaint
- Note the complaint ID

### Step 4: Logout and login as Admin
- Logout from User A account
- Login with admin credentials
- Go to Admin Dashboard

### Step 5: Mark complaint as fixed
- Find User A's complaint in the list
- Click on the complaint
- Click "Mark Fixed" button
- Wait 2-3 seconds

### Step 6: Check notification
- Look at User A's device notification bar
- Should see: "Complaint Fixed! ✓"
- Body: "Your complaint has been resolved."

---

## Phase 3: Troubleshooting Commands

### Check if function deployed
```bash
firebase functions:list
```

### View function logs
```bash
firebase functions:log --limit 50
```

### View real-time logs
```bash
firebase functions:log
```

### Check specific function
```bash
firebase functions:log notifyComplaintFixed
```

### Rebuild and redeploy
```bash
cd functions
npm run build
firebase deploy --only functions
```

### Check Firestore data
```bash
firebase firestore:list
```

---

## Phase 4: Verify Setup

### Check 1: FCM Token Saved
```bash
firebase firestore:get users/{userId}
```
Should show `fcmToken` field

### Check 2: Function Exists
```bash
firebase functions:list
```
Should show `notifyComplaintFixed`

### Check 3: Logs Working
```bash
firebase functions:log --limit 10
```
Should show recent function executions

---

## Complete Deployment Script

Run these commands in sequence:

```bash
# Navigate to project root
cd d:\Study\Sem - II\MAD\fix_my_campus

# Go to functions directory
cd functions

# Install dependencies
npm install

# Build TypeScript
npm run build

# Deploy functions
firebase deploy --only functions

# Verify deployment
firebase functions:list

# View logs
firebase functions:log
```

---

## Quick Test Commands

```bash
# After deploying, run these to test:

# 1. Check function deployed
firebase functions:list

# 2. View logs while testing
firebase functions:log

# 3. Check user FCM token
firebase firestore:get users/{userId}

# 4. Check complaint data
firebase firestore:get complaints/{complaintId}
```

---

## Emergency Troubleshooting

### If deployment fails:
```bash
cd functions
npm run build
firebase deploy --only functions --debug
```

### If function not triggering:
```bash
firebase functions:log --limit 100
```
Look for error messages

### If FCM token not saving:
```bash
firebase firestore:get users/{userId}
```
Check if `fcmToken` field exists

### If notification not appearing:
1. Check device notification settings
2. Verify FCM token exists
3. Check function logs
4. Verify complaint has `userEmail` field

---

## Monitoring Commands

### Real-time monitoring
```bash
firebase functions:log
```

### Last 50 executions
```bash
firebase functions:log --limit 50
```

### Last 100 executions
```bash
firebase functions:log --limit 100
```

### Specific function logs
```bash
firebase functions:log notifyComplaintFixed
```

---

## Cleanup Commands (if needed)

### Delete function (not recommended)
```bash
firebase functions:delete notifyComplaintFixed
```

### Clear all logs
```bash
firebase functions:log --clear
```

---

## Success Indicators

✅ **Deployment successful when:**
- `firebase functions:list` shows `notifyComplaintFixed`
- `firebase deploy --only functions` shows "✔ functions deployed successfully"
- `firebase functions:log` shows function executions

✅ **Testing successful when:**
- Notification appears in device notification bar
- `firebase functions:log` shows "Notification sent successfully"
- FCM token exists in Firestore

---

## Command Reference Table

| Command | Purpose | Expected Output |
|---------|---------|-----------------|
| `npm install` | Install dependencies | "added X packages" |
| `npm run build` | Compile TypeScript | No errors |
| `firebase deploy --only functions` | Deploy | "✔ functions deployed successfully" |
| `firebase functions:list` | List functions | Shows `notifyComplaintFixed` |
| `firebase functions:log` | View logs | Shows function executions |
| `firebase firestore:get users/{id}` | Check user data | Shows user document with fcmToken |

---

## Next Steps

1. **Run deployment commands** (Phase 1)
2. **Test on device** (Phase 2)
3. **Check logs** (Phase 3)
4. **Verify setup** (Phase 4)
5. **Monitor** (Phase 4 - Monitoring Commands)

**Start here:**
```bash
cd functions
npm install
firebase deploy --only functions
```
