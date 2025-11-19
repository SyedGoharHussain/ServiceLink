/**
 * Cloud Functions for Firebase - Push Notification Handler
 * Sends FCM push notifications when new messages are queued in Firestore
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Initialize Firebase Admin SDK
admin.initializeApp();

/**
 * Send FCM push notification when a new message is queued
 * Triggers on new document creation in fcm_messages collection
 */
exports.sendFCMNotification = functions.firestore
    .document("fcm_messages/{messageId}")
    .onCreate(async (snap, context) => {
      const messageData = snap.data();

      // Skip if already processed
      if (messageData.processed) {
        console.log("Message already processed:", context.params.messageId);
        return null;
      }

      try {
        console.log("Processing FCM message:", context.params.messageId);
        console.log("Recipient token:", messageData.to);
        console.log("Notification:", messageData.notification);

        // Construct the FCM message
        const message = {
          token: messageData.to,
          notification: {
            title: messageData.notification.title,
            body: messageData.notification.body,
          },
          data: messageData.data || {},
          android: {
            priority: "high",
            notification: {
              channelId: messageData.android?.notification?.channelId || "high_importance_channel",
              sound: "default",
              priority: "high",
              visibility: "public",
              defaultVibrateTimings: true,
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
              },
            },
          },
        };

        // Send the notification via FCM
        const response = await admin.messaging().send(message);
        console.log("✅ Successfully sent message:", response);

        // Mark as processed in Firestore
        await snap.ref.update({
          processed: true,
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
          messageId: response,
          status: "sent",
        });

        return response;
      } catch (error) {
        console.error("❌ Error sending message:", error);

        // Mark as failed in Firestore
        await snap.ref.update({
          processed: true,
          error: error.message,
          errorCode: error.code,
          failedAt: admin.firestore.FieldValue.serverTimestamp(),
          status: "failed",
        });

        return null;
      }
    });

/**
 * Clean up old FCM messages (older than 7 days)
 * Runs daily at midnight UTC
 */
exports.cleanupOldMessages = functions.pubsub
    .schedule("0 0 * * *")
    .timeZone("UTC")
    .onRun(async (context) => {
      const db = admin.firestore();
      const sevenDaysAgo = new Date();
      sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

      console.log("🧹 Starting cleanup of old messages...");

      try {
        const snapshot = await db.collection("fcm_messages")
            .where("timestamp", "<", sevenDaysAgo)
            .limit(500)
            .get();

        if (snapshot.empty) {
          console.log("No old messages to clean up");
          return null;
        }

        const batch = db.batch();
        snapshot.docs.forEach((doc) => {
          batch.delete(doc.ref);
        });

        await batch.commit();
        console.log(`✅ Deleted ${snapshot.size} old messages`);

        return null;
      } catch (error) {
        console.error("❌ Error during cleanup:", error);
        return null;
      }
    });

/**
 * Test function to verify deployment
 */
exports.testNotification = functions.https.onRequest(async (req, res) => {
  res.json({
    status: "success",
    message: "Cloud Functions are deployed and working!",
    timestamp: new Date().toISOString(),
    functions: [
      "sendFCMNotification - Sends push notifications",
      "cleanupOldMessages - Cleans up old messages daily",
    ],
  });
});
