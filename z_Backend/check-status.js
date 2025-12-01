require('dotenv').config();
const mongoose = require('mongoose');
const { VolunteerProfile, SosCase } = require('./models');

async function checkStatus() {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('Connected to MongoDB');

        const volunteerId = '69098015593b3ba819856918';
        const volunteer = await VolunteerProfile.findOne({ userId: volunteerId });

        if (volunteer) {
            console.log(`Volunteer Status: ${volunteer.status}`);
            console.log(`Volunteer Ready: ${volunteer.ready}`);
            console.log(`HomeBase: ${JSON.stringify(volunteer.homeBase?.location)}`);
        } else {
            console.log('Volunteer not found');
        }

        const pendingCount = await SosCase.countDocuments({ status: 'SEARCHING' });
        console.log(`Pending SOS Cases: ${pendingCount}`);

        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

checkStatus();
