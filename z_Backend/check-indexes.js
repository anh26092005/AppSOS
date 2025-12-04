const mongoose = require('mongoose');
require('dotenv').config();

async function checkIndexes() {
    try {
        await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/appsos');
        console.log('✅ Connected to MongoDB\n');

        const db = mongoose.connection.db;
        const usersCollection = db.collection('users');

        // List all indexes
        const indexes = await usersCollection.indexes();
        console.log('📋 Current indexes on users collection:\n');
        indexes.forEach((index, i) => {
            console.log(`${i + 1}. ${index.name}:`);
            console.log(`   Key: ${JSON.stringify(index.key)}`);
            console.log(`   Unique: ${index.unique || false}`);
            console.log(`   Sparse: ${index.sparse || false}`);
            console.log('');
        });

    } catch (error) {
        console.error('❌ Error:', error);
    } finally {
        await mongoose.disconnect();
        console.log('👋 Disconnected from MongoDB');
        process.exit(0);
    }
}

checkIndexes();
