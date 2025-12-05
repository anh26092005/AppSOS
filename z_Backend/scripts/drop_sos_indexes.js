const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');

// Try loading from multiple possible locations
const envPaths = [
    path.join(__dirname, '../.env'),
    path.join(process.cwd(), '.env'),
];

for (const p of envPaths) {
    const result = dotenv.config({ path: p });
    if (!result.error) break;
}

const connectDB = async () => {
    try {
        const conn = await mongoose.connect(process.env.MONGO_URI);
        console.log(`MongoDB Connected: ${conn.connection.host}`);
    } catch (error) {
        console.error(`Error: ${error.message}`);
        process.exit(1);
    }
};

const dropIndexes = async () => {
    try {
        await connectDB();
        const SosCase = require('../models/sosCase.model');

        console.log('Dropping indexes for SosCase collection...');

        // Drop specific indexes if they exist
        try {
            await SosCase.collection.dropIndex('location_2dsphere');
            console.log('✅ Dropped location_2dsphere');
        } catch (e) { console.log('Index location_2dsphere not found or error:', e.message); }

        try {
            await SosCase.collection.dropIndex('responderLocation_2dsphere');
            console.log('✅ Dropped responderLocation_2dsphere');
        } catch (e) { console.log('Index responderLocation_2dsphere not found or error:', e.message); }

        // Recreate only the necessary one (if needed, but usually model handles it)
        // For now, let's just drop the duplicates. The model definition likely creates 'location_2dsphere'

        const indexes = await SosCase.collection.indexes();
        console.log('Remaining Indexes:', JSON.stringify(indexes, null, 2));

        process.exit(0);
    } catch (error) {
        console.error('❌ Error dropping indexes:', error);
        process.exit(1);
    }
};

dropIndexes();
