const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Cloud Function to send FCM push notifications
 * Triggers when a new document is created in fcm_messages collection
 */
exports.sendFCMNotification = functions.firestore
  .document('fcm_messages/{messageId}')
  .onCreate(async (snap, context) => {
    const messageData = snap.data();
    
    // Skip if already processed
    if (messageData.processed) {
      console.log('Message already processed');
      return null;
    }
    
    try {
      // Construct the FCM message
      const message = {
        token: messageData.to,
        notification: {
          title: messageData.notification.title,
          body: messageData.notification.body,
        },
        data: messageData.data || {},
        android: {
          priority: 'high',
          notification: {
            channelId: 'high_importance_channel',
            sound: 'default',
            priority: 'high',
            visibility: 'public',
            defaultVibrateTimings: true,
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };
      
      // Send the notification
      const response = await admin.messaging().send(message);
      console.log('Successfully sent message:', response);
      
      // Mark as processed
      await snap.ref.update({ 
        processed: true,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        messageId: response,
      });
      
      return response;
    } catch (error) {
      console.error('Error sending message:', error);
      
      // Mark as failed
      await snap.ref.update({ 
        processed: true,
        error: error.message,
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      return null;
    }
  });

/**
 * Clean up old fcm_messages (older than 7 days)
 * Runs daily at midnight
 */
exports.cleanupOldMessages = functions.pubsub
  .schedule('0 0 * * *')
  .timeZone('UTC')
  .onRun(async (context) => {
    const db = admin.firestore();
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    
    const snapshot = await db.collection('fcm_messages')
      .where('timestamp', '<', sevenDaysAgo)
      .limit(500)
      .get();
    
    if (snapshot.empty) {
      console.log('No old messages to clean up');
      return null;
    }
    
    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });
    
    await batch.commit();
    console.log(`Deleted ${snapshot.size} old messages`);
    
    return null;
  });
