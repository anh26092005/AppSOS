const mongoose = require('mongoose');
require('dotenv').config();

async function deleteGoogleUsers() {
    try {
        await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/appsos');
        console.log('✅ Connected to MongoDB\n');

        const db = mongoose.connection.db;
        const usersCollection = db.collection('users');

        // Find Google user with your email
        const googleUser = await usersCollection.findOne({
            email: 'nhoth9518@ut.edu.vn',
            authProvider: 'google'
        });

        if (googleUser) {
            console.log('🔍 Found Google user:');
            console.log(`   Name: ${googleUser.fullName}`);
            console.log(`   Email: ${googleUser.email}`);
            console.log(`   Firebase UID: ${googleUser.firebaseUid}`);
            console.log(`   _id: ${googleUser._id}\n`);

            console.log('🗑️  Deleting this user...');
            await usersCollection.deleteOne({ _id: googleUser._id });
            console.log('✅ User deleted!\n');
        } else {
            console.log('❌ No Google user found with email nhoth9518@ut.edu.vn\n');
        }

        // Count remaining users with null phone
        const nullPhoneCount = await usersCollection.countDocuments({ phone: null });
        console.log(`📊 Remaining users with phone: null = ${nullPhoneCount}`);

    } catch (error) {
        console.error('❌ Error:', error);
    } finally {
        await mongoose.disconnect();
        console.log('\n👋 Disconnected from MongoDB');
        process.exit(0);
    }
}

deleteGoogleUsers();
