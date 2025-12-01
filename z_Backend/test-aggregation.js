require('dotenv').config();
const mongoose = require('mongoose');
const { SosCase, VolunteerProfile } = require('./models');

async function testAggregation() {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('Connected to MongoDB');

        const volunteerId = '69098015593b3ba819856918'; // The user's ID
        const volunteer = await VolunteerProfile.findOne({ userId: volunteerId });

        if (!volunteer) {
            console.log('Volunteer not found');
            process.exit(1);
        }

        console.log('Volunteer Location:', JSON.stringify(volunteer.homeBase.location));

        console.log('Testing Aggregation...');

        try {
            const pendingCases = await SosCase.aggregate([
                {
                    $geoNear: {
                        near: volunteer.homeBase.location,
                        distanceField: 'distance',
                        maxDistance: 50000, // 50km
                        spherical: true,
                        key: 'location',
                        query: { status: 'SEARCHING' }
                    }
                },
                {
                    $sort: { createdAt: 1 }
                },
                {
                    $limit: 10
                }
            ]);

            console.log(`Found ${pendingCases.length} pending cases.`);
            pendingCases.forEach(c => {
                console.log(`- Case ${c.code}: ${c.distance}m away`);
            });

        } catch (aggError) {
            console.error('Aggregation Failed:', aggError);
        }

        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

testAggregation();
