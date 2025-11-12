const admin = require('firebase-admin');
const { Device, Notification } = require('../models');

// Khởi tạo Firebase Admin (chỉ một lần)
let firebaseInitialized = false;

/**
 * Khởi tạo Firebase Admin SDK
 * Lấy service account từ biến môi trường hoặc file config
 */
const initializeFirebase = () => {
  if (firebaseInitialized) {
    return;
  }

  try {
    let serviceAccount;

    // Thử lấy từ biến môi trường trước
    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
      try {
        serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
      } catch (error) {
        console.error('Error parsing FIREBASE_SERVICE_ACCOUNT:', error.message);
        throw new Error('Invalid FIREBASE_SERVICE_ACCOUNT JSON format');
      }
    } else {
      // Fallback: lấy từ file config
      try {
        serviceAccount = require('../config/firebase-service-account.json');
      } catch (error) {
        throw new Error(
          'Firebase service account not found. Please set FIREBASE_SERVICE_ACCOUNT environment variable or create config/firebase-service-account.json'
        );
      }
    }

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });

    firebaseInitialized = true;
    console.log('Firebase Admin SDK initialized successfully');
  } catch (error) {
    console.error('Failed to initialize Firebase:', error.message);
    throw error;
  }
};

/**
 * Gửi thông báo đơn lẻ cho một thiết bị
 * @param {string} pushToken - FCM token của thiết bị
 * @param {string} title - Tiêu đề thông báo
 * @param {string} body - Nội dung thông báo
 * @param {object} data - Dữ liệu bổ sung (sẽ được convert sang string)
 * @returns {Promise<object>} Kết quả gửi thông báo
 */
const sendPushNotification = async (pushToken, title, body, data = {}) => {
  try {
    if (!firebaseInitialized) {
      throw new Error('Firebase not initialized');
    }

    // Convert tất cả giá trị trong data sang string (yêu cầu của FCM)
    const stringifiedData = Object.keys(data).reduce((acc, key) => {
      acc[key] = String(data[key]);
      return acc;
    }, {});

    const message = {
      notification: {
        title,
        body,
      },
      data: stringifiedData,
      token: pushToken,
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'sos_emergency',
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

    const response = await admin.messaging().send(message);
    console.log('Successfully sent message:', response);
    return { success: true, messageId: response };
  } catch (error) {
    console.error('Error sending push notification:', error);

    // Xóa token không hợp lệ
    if (
      error.code === 'messaging/invalid-registration-token' ||
      error.code === 'messaging/registration-token-not-registered'
    ) {
      try {
        await Device.findOneAndDelete({ pushToken });
        console.log(`Removed invalid token: ${pushToken}`);
      } catch (dbError) {
        console.error('Error removing invalid token:', dbError);
      }
    }

    return { success: false, error: error.message };
  }
};

/**
 * Gửi thông báo cho nhiều thiết bị
 * @param {string[]} pushTokens - Mảng các FCM token
 * @param {string} title - Tiêu đề thông báo
 * @param {string} body - Nội dung thông báo
 * @param {object} data - Dữ liệu bổ sung
 * @returns {Promise<object>} Kết quả gửi thông báo
 */
const sendMulticastNotification = async (pushTokens, title, body, data = {}) => {
  try {
    if (!firebaseInitialized) {
      throw new Error('Firebase not initialized');
    }

    if (!pushTokens || pushTokens.length === 0) {
      return { success: false, error: 'No push tokens provided' };
    }

    // Convert tất cả giá trị trong data sang string
    const stringifiedData = Object.keys(data).reduce((acc, key) => {
      acc[key] = String(data[key]);
      return acc;
    }, {});

    const message = {
      notification: {
        title,
        body,
      },
      data: stringifiedData,
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'sos_emergency',
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
      tokens: pushTokens,
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(`Successfully sent ${response.successCount} messages`);
    console.log(`Failed ${response.failureCount} messages`);

    // Xóa các token không hợp lệ
    if (response.failureCount > 0) {
      const invalidTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          if (
            resp.error?.code === 'messaging/invalid-registration-token' ||
            resp.error?.code === 'messaging/registration-token-not-registered'
          ) {
            invalidTokens.push(pushTokens[idx]);
          }
        }
      });

      if (invalidTokens.length > 0) {
        try {
          await Device.deleteMany({ pushToken: { $in: invalidTokens } });
          console.log(`Removed ${invalidTokens.length} invalid tokens`);
        } catch (dbError) {
          console.error('Error removing invalid tokens:', dbError);
        }
      }
    }

    return {
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount,
    };
  } catch (error) {
    console.error('Error sending multicast notification:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Gửi thông báo cho user (tất cả devices của user)
 * @param {string} userId - ID của user
 * @param {string} title - Tiêu đề thông báo
 * @param {string} body - Nội dung thông báo
 * @param {object} data - Dữ liệu bổ sung
 * @returns {Promise<object>} Kết quả gửi thông báo
 */
const sendNotificationToUser = async (userId, title, body, data = {}) => {
  try {
    // Lấy tất cả device của user
    const devices = await Device.find({ userId });

    if (devices.length === 0) {
      console.log(`No devices found for user: ${userId}`);
      return { success: false, error: 'No devices found for user' };
    }

    const pushTokens = devices.map((device) => device.pushToken);

    // Gửi thông báo
    const result = await sendMulticastNotification(pushTokens, title, body, data);

    // Lưu vào database nếu gửi thành công
    if (result.success && result.successCount > 0) {
      try {
        await Notification.create({
          userId,
          type: data.type || 'GENERAL',
          title,
          body,
          data,
          deliveredAt: new Date(),
        });
      } catch (dbError) {
        console.error('Error saving notification to database:', dbError);
        // Không throw error, vì FCM đã gửi thành công
      }
    }

    return result;
  } catch (error) {
    console.error('Error sending notification to user:', error);
    return { success: false, error: error.message };
  }
};

module.exports = {
  initializeFirebase,
  sendPushNotification,
  sendMulticastNotification,
  sendNotificationToUser,
};

