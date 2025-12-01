require('dotenv').config();
const mongoose = require('mongoose');
const { SosCase, SosResponderQueue, VolunteerProfile } = require('./models');

async function debugLatestSos() {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('Connected to MongoDB');

        // Get latest SOS case
        const latestSos = await SosCase.findOne().sort({ createdAt: -1 });

        if (!latestSos) {
            console.log('❌ No SOS cases found.');
            process.exit(0);
        }

        console.log('=== Latest SOS Case ===');
        console.log(`ID: ${latestSos._id}`);
        console.log(`Code: ${latestSos.code}`);
        console.log(`Status: ${latestSos.status}`);
        console.log(`Location: ${JSON.stringify(latestSos.location)}`);
        console.log(`Created At: ${latestSos.createdAt}`);
        console.log(`Reporter: ${latestSos.reporterId}`);

        // Check Queue for this case
        const queueItems = await SosResponderQueue.find({ sosId: latestSos._id });
        console.log(`\n=== Responder Queue (${queueItems.length} items) ===`);
        queueItems.forEach(item => {
            console.log(`- Vol: ${item.volunteerId} | Status: ${item.status} | Dist: ${item.distanceKm}km`);
        });

        // Check the specific volunteer status
        const volunteerId = '69098015593b3ba819856918';
        const volunteer = await VolunteerProfile.findOne({ userId: volunteerId });
        console.log(`\n=== Target Volunteer (${volunteerId}) ===`);
        if (volunteer) {
            console.log(`Status: ${volunteer.status}`);
            console.log(`Ready: ${volunteer.ready}`);
            console.log(`Location: ${JSON.stringify(volunteer.homeBase.location)}`);

            // Calculate distance manually
            if (latestSos.location && volunteer.homeBase.location) {
                // Simple Euclidean for rough check (not accurate for geo but okay for debugging small dist)
                // Better to rely on what the aggregation said, but we can't see that here.
                console.log('Volunteer exists and has location.');
            }
        } else {
            console.log('❌ Volunteer profile not found.');
        }

        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

debugLatestSos();
