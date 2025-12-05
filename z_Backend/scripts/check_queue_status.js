const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');

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

const checkQueue = async () => {
    try {
        await connectDB();
        const SosCase = require('../models/sosCase.model');
        const SosResponderQueue = require('../models/sosResponderQueue.model');

        // Get latest SOS case
        const latestCase = await SosCase.findOne().sort({ createdAt: -1 });

        if (!latestCase) {
            console.log('No SOS cases found');
            process.exit(0);
        }

        console.log('Latest Case:', {
            _id: latestCase._id,
            code: latestCase.code,
            status: latestCase.status,
            createdAt: latestCase.createdAt,
            meta: latestCase.meta
        });

        // Get queue items
        const queueItems = await SosResponderQueue.find({ sosId: latestCase._id });

        console.log(`Found ${queueItems.length} queue items:`);
        queueItems.forEach(item => {
            console.log({
                volunteerId: item.volunteerId,
                status: item.status,
                notifiedAt: item.notifiedAt,
                declineReason: item.declineReason
            });
        });

        process.exit(0);
    } catch (error) {
        console.error('❌ Error checking queue:', error);
        process.exit(1);
    }
};

checkQueue();
