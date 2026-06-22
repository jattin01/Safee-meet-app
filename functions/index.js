/**
 * SAFEE MEET — Cloud Function: sendChatNotification
 *
 * Triggers when a new message is written to:
 *   chat_rooms/{roomId}/messages/{messageId}
 *
 * Reads the receiver's FCM token from:
 *   users/{receiverId}.fcmToken
 *
 * Sends a push notification to the receiver's device.
 *
 * Deploy:
 *   cd functions
 *   npm install
 *   firebase deploy --only functions
 */

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

exports.sendChatNotification = onDocumentCreated(
  'chat_rooms/{roomId}/messages/{messageId}',
  async (event) => {
    const message = event.data.data();
    if (!message) return;

    const { senderId, receiverId, message: content } = message;

    // Don't notify if receiver is the same as sender
    if (!receiverId || receiverId === senderId) return;

    try {
      // Get receiver's FCM token and online status
      const db = getFirestore();
      const receiverDoc = await db.collection('users').doc(receiverId).get();
      if (!receiverDoc.exists) return;

      const receiver = receiverDoc.data();
      const { fcmToken, isOnline, name: receiverName } = receiver;

      // Skip notification if receiver is online (they see the message in real time)
      if (isOnline) return;

      if (!fcmToken) return;

      // Get sender name
      const senderDoc = await db.collection('users').doc(senderId).get();
      const senderName = senderDoc.exists
        ? (senderDoc.data().name || 'Someone')
        : 'Someone';

      const roomId = event.params.roomId;

      // Send FCM notification
      await getMessaging().send({
        token: fcmToken,
        notification: {
          title: senderName,
          body: content.length > 100 ? content.substring(0, 97) + '…' : content,
        },
        data: {
          // App uses these to navigate to the correct chat on tap
          type: 'chat_message',
          roomId: roomId,
          senderId: senderId,
          senderName: senderName,
        },
        android: {
          notification: {
            channelId: 'chat_messages',
            priority: 'high',
            sound: 'default',
          },
          priority: 'high',
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      });

      console.log(`Notification sent to ${receiverId} for message in room ${roomId}`);
    } catch (err) {
      console.error('sendChatNotification error:', err);
    }
  }
);
