# Supabase Edge Functions for Push Notifications

## Advantages Over Firebase Cloud Functions

✅ **Completely FREE** - No upgrade needed
✅ **No credit card required** - Free tier is unlimited
✅ **Easier setup** - No need to upgrade plan
✅ **Same functionality** - Sends FCM notifications

## Cost Comparison

| Feature | Firebase | Supabase |
|---------|----------|----------|
| Free Tier | 2M invocations/month | Unlimited |
| Upgrade Required | YES (Blaze plan) | NO |
| Credit Card | Required | Not required |
| Cost for 1000 notifications | $0 (free tier) | $0 (free) |

## Setup Steps

### Step 1: Install Supabase CLI
```bash
npm install -g supabase
```

### Step 2: Login to Supabase
```bash
supabase login
```

### Step 3: Create Edge Function
```bash
supabase functions new send-notification
```

### Step 4: Copy Function Code
Replace `supabase/functions/send-notification/index.ts` with code from `supabase_edge_function.ts`

### Step 5: Set Environment Variables
```bash
supabase secrets set FIREBASE_PROJECT_ID="your-project-id"
supabase secrets set FIREBASE_API_KEY="your-firebase-api-key"
```

Get these from:
- **FIREBASE_PROJECT_ID**: Firebase Console → Project Settings
- **FIREBASE_API_KEY**: Firebase Console → Project Settings → Web API Key

### Step 6: Deploy
```bash
supabase functions deploy send-notification
```

You'll get a URL like:
```
https://your-project.supabase.co/functions/v1/send-notification
```

## How It Works

### Trigger Method 1: HTTP Request (Recommended)
When admin marks complaint as fixed:
1. Call Supabase Edge Function via HTTP
2. Function fetches user's FCM token
3. Sends FCM message to user's device
4. User receives notification

### Trigger Method 2: Database Trigger
Set up a Supabase trigger to automatically call the function when complaint status changes.

## Update Flutter App

Update `complaint_detail_screen.dart` to call Supabase function:

```dart
Future<void> _updateStatus(String newStatus) async {
  setState(() => _isUpdating = true);
  
  try {
    await FirebaseFirestore.instance
        .collection('complaints')
        .doc(widget.complaint.id)
        .update({
          'status': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });
    
    setState(() => _currentStatus = newStatus);

    // Call Supabase Edge Function
    if (newStatus == 'fixed') {
      final response = await http.post(
        Uri.parse('https://YOUR_PROJECT.supabase.co/functions/v1/send-notification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'complaintId': widget.complaint.id,
          'userId': widget.complaint['userId'],
          'status': newStatus,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status updated and notification sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  } finally {
    setState(() => _isUpdating = false);
  }
}
```

## Testing

### Test 1: Check Function Deployment
```bash
supabase functions list
```

### Test 2: Test Function Manually
```bash
curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/send-notification \
  -H "Content-Type: application/json" \
  -d '{
    "complaintId": "test123",
    "userId": "user123",
    "status": "fixed"
  }'
```

### Test 3: End-to-End Test
1. Login on Phone A
2. Login as admin on Phone B
3. Mark complaint as fixed on Phone B
4. Phone A should receive notification

## Troubleshooting

### Function not deploying?
```bash
supabase functions deploy send-notification --no-verify-jwt
```

### Notification not received?
1. Check FCM token is saved (use Debug Screen)
2. Check Firebase API key is correct
3. Check function logs: `supabase functions logs send-notification`

### "Permission denied" error?
Make sure you're using `SUPABASE_SERVICE_ROLE_KEY` (not anon key)

## File Structure
```
your-project/
├── supabase/
│   ├── functions/
│   │   └── send-notification/
│   │       └── index.ts
│   └── config.toml
└── ...
```

## Cost

**Supabase Edge Functions:**
- Free tier: **Unlimited** invocations
- Paid: $0.000002 per invocation (if you somehow exceed free tier)

For a campus app: **$0/month** 🎉

## Advantages

✅ No upgrade needed
✅ No credit card required
✅ Unlimited free tier
✅ Same functionality as Firebase
✅ Easier to set up

## Next Steps

1. Install Supabase CLI
2. Login to Supabase
3. Create Edge Function
4. Copy function code
5. Set environment variables
6. Deploy
7. Update Flutter app with function URL
8. Test!

## Support

If you have issues:
1. Check Supabase function logs
2. Verify Firebase API key
3. Check FCM token in Firestore
4. Ensure notification permission is granted

This is the **easiest and cheapest** solution! 🚀
