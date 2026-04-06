import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import axios from "axios";

admin.initializeApp();

const ONESIGNAL_APP_ID = process.env.ONESIGNAL_APP_ID || "9d4ccec5-d7b2-4cb3-a219-6089025a7cdd";
const ONESIGNAL_API_KEY = process.env.ONESIGNAL_API_KEY || "<your-onesignal-api-key>";

export const notifyComplaintFixed = functions.firestore
  .document("complaints/{complaintId}")
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();

    // Check if status changed to 'fixed'
    if (oldData.status !== "fixed" && newData.status === "fixed") {
      const userEmail = newData.userEmail;
      const complaintTitle = newData.complaint || "Your complaint";
      const complaintId = context.params.complaintId;

      try {
        // Get user's OneSignal ID from Firestore
        const userSnapshot = await admin
          .firestore()
          .collection("users")
          .where("email", "==", userEmail)
          .limit(1)
          .get();

        if (!userSnapshot.empty) {
          const oneSignalId = userSnapshot.docs[0].data().oneSignalId;

          if (oneSignalId) {
            // Send notification via OneSignal REST API
            const response = await axios.post(
              "https://onesignal.com/api/v1/notifications",
              {
                app_id: ONESIGNAL_APP_ID,
                include_player_ids: [oneSignalId],
                headings: { en: "Your Complaint is Fixed!" },
                contents: {
                  en: `Your complaint "${complaintTitle}" has been marked as fixed.`,
                },
                data: {
                  complaintId: complaintId,
                  type: "complaint_fixed",
                },
              },
              {
                headers: {
                  Authorization: `Basic ${ONESIGNAL_API_KEY}`,
                  "Content-Type": "application/json; charset=utf-8",
                },
              }
            );
            console.log("Notification sent successfully:", response.data);
          } else {
            console.log("No OneSignal ID found for user:", userEmail);
          }
        } else {
          console.log("User not found:", userEmail);
        }
      } catch (error) {
        console.error("Error sending notification:", error);
      }
    }
  });
