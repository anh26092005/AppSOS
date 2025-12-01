require('dotenv').config();
const mongoose = require('mongoose');
const { SosResponderQueue, SosCase } = require('./models');

async function checkQueue() {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('Connected to MongoDB');

        const volunteerId = '69098015593b3ba819856918';

        console.log(`Checking queue for volunteer: ${volunteerId}`);

        const queueItems = await SosResponderQueue.find({ volunteerId })
            .populate('sosId', 'code status emergencyType')
            .sort({ createdAt: -1 });

        console.log(`Found ${queueItems.length} queue items:`);
        queueItems.forEach(item => {
            console.log(`- Case: ${item.sosId?.code} (${item.sosId?.status}) | Status: ${item.status} | Date: ${item.createdAt}`);
        });

        // Check if they are considered "busy" or "notified" by the controller logic
        const busyVolunteers = await SosCase.find({
            status: { $in: ['ACCEPTED', 'IN_PROGRESS'] },
            acceptedBy: volunteerId,
        });
        console.log(`Busy (Accepted/InProgress Cases): ${busyVolunteers.length}`);

        const searchingCaseIds = await SosCase.find({ status: 'SEARCHING' }).distinct('_id');
        const notifiedQueue = await SosResponderQueue.find({
            sosId: { $in: searchingCaseIds },
            status: 'NOTIFIED',
            volunteerId
        });
        console.log(`Notified (Pending Cases): ${notifiedQueue.length}`);

        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

checkQueue();
