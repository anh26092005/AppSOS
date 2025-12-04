const mongoose = require('mongoose');
require('dotenv').config();

async function checkDuplicateUsers() {
    try {
        await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/appsos');
        console.log('✅ Connected to MongoDB\n');

        const db = mongoose.connection.db;
        const usersCollection = db.collection('users');

        // Count users with null phone
        const nullPhoneCount = await usersCollection.countDocuments({ phone: null });
        console.log(`📊 Users with phone: null = ${nullPhoneCount}`);

        // Find all users with null phone
        const nullPhoneUsers = await usersCollection.find({ phone: null }).toArray();
        console.log('\n📋 Users with null phone:');
        nullPhoneUsers.forEach((user, index) => {
            console.log(`\n${index + 1}. ${user.fullName || 'No name'}`);
            console.log(`   Email: ${user.email || 'No email'}`);
            console.log(`   Provider: ${user.authProvider}`);
            console.log(`   Firebase UID: ${user.firebaseUid || 'None'}`);
            console.log(`   _id: ${user._id}`);
        });

        // Check for your specific email
        const yourEmail = 'nhoth9518@ut.edu.vn';
        const existingUser = await usersCollection.findOne({ email: yourEmail });

        console.log(`\n\n🔍 Checking for user with email: ${yourEmail}`);
        if (existingUser) {
            console.log('✅ User exists:');
            console.log(`   Name: ${existingUser.fullName}`);
            console.log(`   Phone: ${existingUser.phone}`);
            console.log(`   Provider: ${existingUser.authProvider}`);
            console.log(`   Firebase UID: ${existingUser.firebaseUid}`);
            console.log(`   _id: ${existingUser._id}`);
        } else {
            console.log('❌ No user found with this email');
        }

    } catch (error) {
        console.error('❌ Error:', error);
    } finally {
        await mongoose.disconnect();
        console.log('\n👋 Disconnected from MongoDB');
        process.exit(0);
    }
}

checkDuplicateUsers();
