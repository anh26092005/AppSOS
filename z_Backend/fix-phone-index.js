const mongoose = require('mongoose');
require('dotenv').config();

async function fixPhoneIndex() {
    try {
        // Connect to MongoDB
        await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/appsos');
        console.log('✅ Connected to MongoDB');

        const db = mongoose.connection.db;
        const usersCollection = db.collection('users');

        // List all indexes
        console.log('\n📋 Current indexes:');
        const indexes = await usersCollection.indexes();
        indexes.forEach(index => {
            console.log(`  - ${JSON.stringify(index)}`);
        });

        // Check if phone_1 index exists
        const phoneIndexExists = indexes.some(idx => idx.name === 'phone_1');

        if (phoneIndexExists) {
            console.log('\n🗑️  Dropping old phone_1 index...');
            await usersCollection.dropIndex('phone_1');
            console.log('✅ Old index dropped');
        } else {
            console.log('\n⚠️  No old phone_1 index found');
        }

        // Recreate index WITHOUT unique constraint
        console.log('\n🔨 Creating new non-unique index on phone...');
        await usersCollection.createIndex(
            { phone: 1 }
            // No unique, no sparse - just a regular index
        );
        console.log('✅ New phone index created (non-unique)');

        // Also ensure email index is sparse
        const emailIndexExists = indexes.some(idx => idx.name === 'email_1');
        if (emailIndexExists) {
            console.log('\n🗑️  Dropping old email_1 index...');
            await usersCollection.dropIndex('email_1');
            console.log('✅ Old email index dropped');
        }

        console.log('\n🔨 Creating new sparse unique index on email...');
        await usersCollection.createIndex(
            { email: 1 },
            { unique: true, sparse: true }
        );
        console.log('✅ New sparse email index created');

        // List indexes after fix
        console.log('\n📋 Indexes after fix:');
        const newIndexes = await usersCollection.indexes();
        newIndexes.forEach(index => {
            console.log(`  - ${JSON.stringify(index)}`);
        });

        console.log('\n✅ All done! You can now login with Google without duplicate key errors.\n');

    } catch (error) {
        console.error('❌ Error:', error);
    } finally {
        await mongoose.disconnect();
        console.log('👋 Disconnected from MongoDB');
        process.exit(0);
    }
}

fixPhoneIndex();
