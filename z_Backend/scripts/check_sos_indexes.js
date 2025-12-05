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

const checkIndexes = async () => {
    try {
        await connectDB();
        const SosCase = require('../models/sosCase.model');

        console.log('Checking indexes for SosCase collection...');
        const indexes = await SosCase.collection.indexes();
        console.log('Current Indexes:', JSON.stringify(indexes, null, 2));

        process.exit(0);
    } catch (error) {
        console.error('❌ Error checking indexes:', error);
        process.exit(1);
    }
};

checkIndexes();
