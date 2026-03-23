// Supabase Edge Function for sending notifications
// File: supabase/functions/send-notification/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL");
const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const firebaseApiKey = Deno.env.get("FIREBASE_API_KEY");

const supabase = createClient(supabaseUrl, supabaseKey);

interface NotificationRequest {
  complaintId: string;
  userId: string;
  status: string;
}

serve(async (req) => {
  // Handle CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST",
        "Access-Control-Allow-Headers": "Content-Type",
      },
    });
  }

  try {
    const { complaintId, userId, status } = (await req.json()) as NotificationRequest;

    console.log(`Sending notification for complaint ${complaintId} with status ${status}`);

    // Get user data from Firestore (since you're using Firebase)
    const userResponse = await fetch(
      `https://firestore.googleapis.com/v1/projects/${Deno.env.get("FIREBASE_PROJECT_ID")}/databases/(default)/documents/users/${userId}`,
      {
        headers: {
          Authorization: `Bearer ${firebaseApiKey}`,
        },
      }
    );

    if (!userResponse.ok) {
      throw new Error("User not found");
    }

    const userData = await userResponse.json();
    const fcmToken = userData.fields?.fcmToken?.stringValue;
    const userName = userData.fields?.username?.stringValue;

    if (!fcmToken) {
      throw new Error("FCM token not found");
    }

    // Prepare notification message
    let title = "";
    let body = "";

    switch (status) {
      case "under_work":
        title = "🔧 Work Started";
        body = `Hi ${userName}, your complaint is now under work!`;
        break;
      case "fixed":
        title = "✅ Complaint Fixed";
        body = `Hi ${userName}, your complaint has been fixed! Thank you for reporting.`;
        break;
      case "pending":
        title = "📢 New Complaint";
        body = `Your complaint has been received.`;
        break;
      default:
        title = "📢 Status Update";
        body = "Your complaint status has been updated.";
    }

    // Send FCM message
    const fcmResponse = await fetch(
      "https://fcm.googleapis.com/v1/projects/" +
        Deno.env.get("FIREBASE_PROJECT_ID") +
        "/messages:send",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${firebaseApiKey}`,
        },
        body: JSON.stringify({
          message: {
            token: fcmToken,
            notification: {
              title: title,
              body: body,
            },
            data: {
              complaintId: complaintId,
              status: status,
              click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
          },
        }),
      }
    );

    if (!fcmResponse.ok) {
      const error = await fcmResponse.text();
      throw new Error(`FCM error: ${error}`);
    }

    const fcmResult = await fcmResponse.json();
    console.log(`Notification sent successfully: ${fcmResult.name}`);

    return new Response(
      JSON.stringify({
        success: true,
        message: "Notification sent",
        messageSid: fcmResult.name,
      }),
      {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  } catch (error) {
    console.error("Error:", error.message);
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
      }),
      {
        status: 400,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  }
});
