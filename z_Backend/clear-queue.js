require('dotenv').config();
const mongoose = require('mongoose');
const { SosResponderQueue } = require('./models');

async function clearQueue() {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('Connected to MongoDB');

        const volunteerId = '69098015593b3ba819856918';

        console.log(`Clearing NOTIFIED queue for volunteer: ${volunteerId}`);

        const result = await SosResponderQueue.deleteMany({
            volunteerId,
            status: 'NOTIFIED'
        });

        console.log(`✅ Deleted ${result.deletedCount} stuck queue items.`);
        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

clearQueue();
