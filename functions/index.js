const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendNotificationOnNewEntry = functions.database
    .ref("/notifications/{notificationId}") // Adjusted path
    .onCreate(async (snapshot, context) => {
      const notification = snapshot.val();
      const title = notification.title || "Default Title";
      const message = notification.message || "Default Message";
      const deviceId = notification.deviceID;
      const userEmail = notification.useremail || "Unknown";

      // Ensure deviceId is valid
      if (!deviceId) {
        console.log("No device ID provided");
        return null;
      }

      const payload = {
        notification: {
          title: title,
          body: message,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        data: {
          useremail: userEmail,
        },
      };

      try {
        const response = await admin.messaging().sendToDevice(
            deviceId,
            payload,
        );
        console.log("Successfully sent message:", response);
        return response;
      } catch (error) {
        console.error("Error sending message:", error);
        return null;
      }
    });
