# Supabase Edge Functions Setup Guide

## Overview
The `send-notification` Edge Function sends FCM push notifications to users' devices. It uses Google's FCM API v1 with service account authentication.

## Prerequisites
- Supabase project created at https://supabase.com
- Firebase project with FCM enabled
- Google service account with FCM permissions

## Step 1: Get Google Service Account Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project
3. Go to **Service Accounts** (Settings → Service Accounts)
4. Click **Generate New Private Key** (JSON format)
5. Save the JSON file - you'll need the contents

## Step 2: Create Supabase Project

1. Go to https://supabase.com and create a new project
2. Note your **Project ID** and **Project URL**
3. Go to **Settings → API** and copy your **anon public key** and **service_role key**

## Step 3: Set Environment Variables

Create a `.env.local` file in your project root with:

```
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
GOOGLE_SERVICE_ACCOUNT={"type":"service_account","project_id":"your-firebase-project","private_key_id":"...","private_key":"-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n","client_email":"firebase-adminsdk-...@your-firebase-project.iam.gserviceaccount.com","client_id":"...","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token","auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs","client_x509_cert_url":"..."}
```

**Important**: The `GOOGLE_SERVICE_ACCOUNT` must be a single-line JSON string with escaped newlines in the private key.

## Step 4: Deploy the Function

```bash
npx supabase functions deploy send-notification --project-ref your-project-id
```

You'll be prompted to enter the `GOOGLE_SERVICE_ACCOUNT` secret. Paste the entire JSON string.

## Step 5: Get Your Function URL

After deployment, your function URL will be:
```
https://your-project-id.supabase.co/functions/v1/send-notification
```

## Step 6: Update Flutter App

In your `lib/services/notification_service.dart`, update the notification sending logic:

```dart
Future<void> sendNotificationToUser(String userId, String title, String body, String complaintId) async {
  try {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final fcmToken = userDoc.data()?['fcmToken'] as String?;
    
    if (fcmToken == null) {
      print('No FCM token found for user $userId');
      return;
    }

    final response = await http.post(
      Uri.parse('https://your-project-id.supabase.co/functions/v1/send-notification'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fcmToken': fcmToken,
        'title': title,
        'body': body,
        'complaintId': complaintId,
      }),
    );

    if (response.statusCode == 200) {
      print('Notification sent successfully');
    } else {
      print('Failed to send notification: ${response.body}');
    }
  } catch (e) {
    print('Error sending notification: $e');
  }
}
```

## Testing Locally

```bash
npx supabase start
npx supabase functions serve
```

Then test with:
```bash
curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/send-notification' \
  --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
  --header 'Content-Type: application/json' \
  --data '{"fcmToken":"your-test-token","title":"Test","body":"Test notification","complaintId":"123"}'
```

## Troubleshooting

- **"Google service account not configured"**: Check that `GOOGLE_SERVICE_ACCOUNT` environment variable is set correctly
- **"Failed to send notification"**: Verify the FCM token is valid and the service account has FCM permissions
- **CORS errors**: The function handles CORS with the OPTIONS method
- **Token expiration**: Access tokens are automatically refreshed (1 hour expiry)

## Cost
- **Completely free** - Supabase Edge Functions have unlimited free tier
- No credit card required
- No usage limits
