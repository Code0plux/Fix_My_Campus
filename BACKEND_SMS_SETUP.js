// BACKEND SETUP GUIDE FOR SMS NOTIFICATIONS
// This guide shows how to set up a Node.js backend to send SMS using Twilio

// ============================================
// 1. INSTALL DEPENDENCIES
// ============================================
// npm install express twilio dotenv cors body-parser

// ============================================
// 2. CREATE .env FILE
// ============================================
/*
TWILIO_ACCOUNT_SID=your_account_sid_here
TWILIO_AUTH_TOKEN=your_auth_token_here
TWILIO_PHONE_NUMBER=+1234567890
PORT=3000
*/

// ============================================
// 3. CREATE server.js
// ============================================

const express = require('express');
const twilio = require('twilio');
const cors = require('cors');
const bodyParser = require('body-parser');
require('dotenv').config();

const app = express();

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Twilio client
const twilioClient = twilio(
  process.env.TWILIO_ACCOUNT_SID,
  process.env.TWILIO_AUTH_TOKEN
);

// ============================================
// 4. SMS ENDPOINT
// ============================================

app.post('/api/send-sms', async (req, res) => {
  try {
    const { phoneNumber, message, complaintId } = req.body;

    // Validate input
    if (!phoneNumber || !message) {
      return res.status(400).json({
        success: false,
        error: 'Phone number and message are required'
      });
    }

    // Send SMS via Twilio
    const result = await twilioClient.messages.create({
      body: message,
      from: process.env.TWILIO_PHONE_NUMBER,
      to: phoneNumber
    });

    console.log(`SMS sent successfully. SID: ${result.sid}`);

    res.status(200).json({
      success: true,
      messageSid: result.sid,
      complaintId: complaintId
    });

  } catch (error) {
    console.error('Error sending SMS:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ============================================
// 5. HEALTH CHECK ENDPOINT
// ============================================

app.get('/api/health', (req, res) => {
  res.status(200).json({ status: 'Server is running' });
});

// ============================================
// 6. START SERVER
// ============================================

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

// ============================================
// SETUP INSTRUCTIONS
// ============================================

/*
1. Sign up for Twilio account at https://www.twilio.com
2. Get your Account SID and Auth Token from Twilio console
3. Get a Twilio phone number
4. Create .env file with credentials
5. Install dependencies: npm install
6. Run server: node server.js
7. Update SMSService._baseUrl in Flutter app to your backend URL
8. Test by sending a complaint and marking it as fixed

IMPORTANT: 
- Keep your Twilio credentials secure
- Use environment variables, never hardcode credentials
- For production, deploy to a service like Heroku, AWS, or DigitalOcean
- Add authentication to your SMS endpoint to prevent abuse
*/

// ============================================
// ALTERNATIVE: USING FIREBASE CLOUD FUNCTIONS
// ============================================

/*
If you prefer to use Firebase Cloud Functions instead:

1. Install Firebase CLI: npm install -g firebase-tools
2. Initialize functions: firebase init functions
3. Install Twilio: npm install twilio
4. Create a callable function:

const functions = require('firebase-functions');
const twilio = require('twilio');

const twilioClient = twilio(
  functions.config().twilio.account_sid,
  functions.config().twilio.auth_token
);

exports.sendSMS = functions.https.onCall(async (data, context) => {
  try {
    const { phoneNumber, message } = data;
    
    const result = await twilioClient.messages.create({
      body: message,
      from: functions.config().twilio.phone_number,
      to: phoneNumber
    });
    
    return { success: true, messageSid: result.sid };
  } catch (error) {
    throw new functions.https.HttpsError('internal', error.message);
  }
});

4. Set config: firebase functions:config:set twilio.account_sid="..." twilio.auth_token="..." twilio.phone_number="..."
5. Deploy: firebase deploy --only functions
6. Update SMSService to use Firebase Cloud Functions instead of HTTP
*/
