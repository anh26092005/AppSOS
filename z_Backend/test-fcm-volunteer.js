require('dotenv').config();
const mongoose = require('mongoose');
const { sendNotificationToUser, initializeFirebase } = require('./services/fcm.service');

async function testFcm() {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('Connected to MongoDB');

        initializeFirebase();

        const volunteerId = '69098015593b3ba819856918';

        console.log(`Sending test notification to volunteer: ${volunteerId}`);

        const result = await sendNotificationToUser(
            volunteerId,
            '🔔 Test Notification',
            'This is a test message from the backend debugger.',
            { type: 'TEST_DEBUG' }
        );

        console.log('Result:', JSON.stringify(result, null, 2));

        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

testFcm();
