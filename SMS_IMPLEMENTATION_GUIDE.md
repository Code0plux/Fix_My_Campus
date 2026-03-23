# SMS Notification Implementation Guide

## Overview
This implementation adds phone number collection during registration and sends SMS notifications to users when their complaints are fixed.

## Changes Made

### 1. **Registration Screen** (`register.dart`)
- Added phone number input field
- Validates phone number (minimum 10 digits)
- Passes phone number to auth service

### 2. **Auth Service** (`auth_service.dart`)
- Updated `register()` method to accept phone number parameter
- Stores phone number in Firestore `users` collection
- Saves phone number in SharedPreferences for local access

### 3. **SMS Service** (`services/sms_service.dart`)
- `sendFixedNotification()` - Sends SMS when complaint is marked as fixed
- `sendStatusUpdateNotification()` - Sends SMS for status updates (pending → under_work)
- Fetches user phone number from Firestore
- Sends HTTP request to backend SMS endpoint

### 4. **Complaint Detail Screen** (`complaint_detail_screen.dart`)
- Calls SMS service when status is updated
- Shows success/error messages for SMS delivery
- Logs SMS sent status in Firestore

## How It Works

### User Registration Flow
```
User enters phone number → Stored in Firestore users collection
                        → Stored in SharedPreferences
```

### SMS Notification Flow
```
Admin marks complaint as "Fixed"
    ↓
Complaint Detail Screen calls SMSService.sendFixedNotification()
    ↓
SMS Service fetches:
  - Complaint details from Firestore
  - User phone number from Firestore
    ↓
Sends HTTP POST to backend: /api/send-sms
    ↓
Backend uses Twilio to send SMS
    ↓
SMS logged in Firestore (smsSent: true, smsSentAt: timestamp)
    ↓
User receives SMS notification
```

## Backend Setup

### Option 1: Node.js + Twilio (Recommended)

**Step 1: Create Node.js Server**
```bash
npm init -y
npm install express twilio dotenv cors body-parser
```

**Step 2: Create .env file**
```
TWILIO_ACCOUNT_SID=your_account_sid
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_PHONE_NUMBER=+1234567890
PORT=3000
```

**Step 3: Create server.js** (see BACKEND_SMS_SETUP.js for full code)

**Step 4: Update SMSService base URL**
```dart
static const String _baseUrl = 'https://your-backend-url.com/api';
```

**Step 5: Deploy Backend**
- Heroku: `git push heroku main`
- AWS Lambda: Use AWS SAM
- DigitalOcean: Deploy Docker container
- Railway.app: Simple deployment platform

### Option 2: Firebase Cloud Functions

**Step 1: Initialize Firebase Functions**
```bash
firebase init functions
npm install twilio
```

**Step 2: Create callable function** (see BACKEND_SMS_SETUP.js for code)

**Step 3: Set Twilio config**
```bash
firebase functions:config:set twilio.account_sid="..." twilio.auth_token="..." twilio.phone_number="..."
```

**Step 4: Deploy**
```bash
firebase deploy --only functions
```

## Twilio Setup

1. **Sign up** at https://www.twilio.com
2. **Get credentials** from Twilio Console:
   - Account SID
   - Auth Token
   - Phone Number (buy one if needed)
3. **Add to backend** .env file
4. **Test** by sending a complaint and marking it as fixed

## Database Schema

### Users Collection
```json
{
  "username": "john_doe",
  "email": "john@example.com",
  "phone": "+919876543210",
  "isAdmin": false,
  "createdAt": "timestamp"
}
```

### Complaints Collection (Updated)
```json
{
  "userId": "user_id",
  "userEmail": "john@example.com",
  "complaint": "Broken light",
  "imageUrl": "url",
  "latitude": 13.0109,
  "longitude": 80.2337,
  "status": "fixed",
  "priority": "high",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "smsSent": true,
  "smsSentAt": "timestamp"
}
```

## Testing

### Test SMS Sending
1. Register a new user with a valid phone number
2. Create a complaint
3. Go to Admin Dashboard
4. Open complaint details
5. Click "Mark Fixed"
6. Check if SMS is sent (check Twilio logs)
7. User should receive SMS notification

### Debug Logs
- Check Flutter console for SMS service logs
- Check backend server logs for HTTP requests
- Check Twilio console for SMS delivery status

## Error Handling

The implementation handles:
- Missing phone number
- Invalid phone number format
- Network errors
- Twilio API errors
- Firestore query failures

All errors are logged and user-friendly messages are shown.

## Security Considerations

1. **Never hardcode credentials** - Use environment variables
2. **Validate phone numbers** - Check format before sending
3. **Rate limiting** - Add rate limiting to SMS endpoint
4. **Authentication** - Add API key authentication to SMS endpoint
5. **HTTPS only** - Always use HTTPS for backend
6. **Sensitive data** - Don't log phone numbers in production

## Cost Estimation

**Twilio Pricing:**
- Outbound SMS: ~$0.0075 per message (varies by country)
- For 1000 SMS/month: ~$7.50
- Free trial: $15 credit

## Troubleshooting

### SMS not sending
- Check Twilio credentials in .env
- Verify phone number format (+country_code format)
- Check backend server is running
- Check network connectivity

### Backend not responding
- Verify backend URL in SMSService
- Check backend server logs
- Ensure CORS is enabled
- Check firewall/network settings

### Phone number not saved
- Check Firestore rules allow write access
- Verify phone number is passed to register()
- Check SharedPreferences permissions

## Future Enhancements

1. **Batch SMS** - Send multiple SMS at once
2. **SMS Templates** - Customizable message templates
3. **Delivery Reports** - Track SMS delivery status
4. **Retry Logic** - Retry failed SMS
5. **WhatsApp Integration** - Send notifications via WhatsApp
6. **Email Fallback** - Send email if SMS fails
7. **Notification Preferences** - Let users choose notification method
