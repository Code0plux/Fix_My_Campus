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
