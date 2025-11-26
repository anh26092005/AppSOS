const { initializeFirebase, sendPushNotification, sendNotificationToUser } = require('./services/fcm.service');
const mongoose = require('mongoose');
require('dotenv').config();

// Kết nối database
const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('MongoDB connected');
  } catch (error) {
    console.error('MongoDB connection error:', error);
    process.exit(1);
  }
};

// Test function
const testFCM = async () => {
  try {
    // 1. Khởi tạo Firebase
    console.log('1. Initializing Firebase...');
    initializeFirebase();
    console.log('✅ Firebase initialized');

    // 2. Lấy device token từ database (hoặc dùng token test)
    const Device = require('./models/device.model');
    const devices = await Device.find().limit(1);
    
    if (devices.length === 0) {
      console.log('❌ No devices found. Please register a device first.');
      console.log('   Use: POST /api/devices/register');
      process.exit(1);
    }

    const testToken = devices[0].pushToken;
    const userId = devices[0].userId;
    
    console.log(`2. Found device token: ${testToken.substring(0, 20)}...`);
    console.log(`   User ID: ${userId}`);

    // 3. Test gửi notification đơn lẻ
    console.log('\n3. Testing single push notification...');
    const result1 = await sendPushNotification(
      testToken,
      '🧪 Test Notification',
      'Đây là thông báo test từ backend',
      {
        type: 'TEST',
        message: 'Hello from FCM!',
        timestamp: new Date().toISOString()
      }
    );
    
    if (result1.success) {
      console.log('✅ Single notification sent successfully!');
      console.log(`   Message ID: ${result1.messageId}`);
    } else {
      console.log('❌ Failed to send notification:', result1.error);
    }

    // 4. Test gửi notification cho user
    console.log('\n4. Testing notification to user...');
    const result2 = await sendNotificationToUser(
      userId,
      '🧪 Test User Notification',
      'Thông báo test cho user',
      {
        type: 'TEST_USER',
        test: 'true'
      }
    );

    if (result2.success) {
      console.log('✅ User notification sent successfully!');
      console.log(`   Success: ${result2.successCount}, Failed: ${result2.failureCount}`);
    } else {
      console.log('❌ Failed to send user notification:', result2.error);
    }

    console.log('\n✅ All tests completed!');
    process.exit(0);

  } catch (error) {
    console.error('❌ Test failed:', error);
    process.exit(1);
  }
};

// Chạy test
(async () => {
  await connectDB();
  await testFCM();
})();