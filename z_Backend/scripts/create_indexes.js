const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');

// Try loading from multiple possible locations
const envPaths = [
    path.join(__dirname, '../.env'), // If running from scripts/
    path.join(process.cwd(), '.env'), // If running from root
];

let loaded = false;
for (const p of envPaths) {
    const result = dotenv.config({ path: p });
    if (!result.error) {
        console.log(`Loaded env from: ${p}`);
        loaded = true;
        break;
    }
}

if (!loaded) {
    console.log('⚠️ Could not load .env file from standard paths');
}

console.log('MONGO_URI defined:', !!process.env.MONGO_URI);

const connectDB = async () => {
    try {
        if (!process.env.MONGO_URI) {
            throw new Error('MONGO_URI is not defined');
        }
        const conn = await mongoose.connect(process.env.MONGO_URI);
        console.log(`MongoDB Connected: ${conn.connection.host}`);
    } catch (error) {
        console.error(`Error: ${error.message}`);
        process.exit(1);
    }
};

const createIndexes = async () => {
    try {
        await connectDB();

        const Device = require('../models/device.model');

        console.log('Creating indexes for Device collection...');

        // Create 2dsphere index on lastLocation
        await Device.collection.createIndex(
            { lastLocation: '2dsphere' },
            {
                name: 'lastLocation_2dsphere',
                background: false
            }
        );

        console.log('✅ Successfully created 2dsphere index on lastLocation');

        // List all indexes
        const indexes = await Device.collection.indexes();
        console.log('Current Indexes:', JSON.stringify(indexes, null, 2));

        process.exit(0);
    } catch (error) {
        console.error('❌ Error creating indexes:', error);
        process.exit(1);
    }
};

createIndexes();
