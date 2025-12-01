require('dotenv').config();
const mongoose = require('mongoose');
const { VolunteerProfile, SosCase, User } = require('./models');

async function debugHistory() {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('Connected to MongoDB');

        const userId = '69098015593b3ba819856918'; // The user ID from logs
        console.log(`\n--- Debugging for User ID: ${userId} ---`);

        // 1. Check User
        const user = await User.findById(userId);
        console.log('1. User found:', user ? 'YES' : 'NO');
        if (!user) {
            console.log('❌ User not found!');
            return;
        }

        // 2. Check VolunteerProfile
        const volunteer = await VolunteerProfile.findOne({ userId: userId });
        console.log('2. VolunteerProfile found:', volunteer ? 'YES' : 'NO');
        if (!volunteer) {
            console.log('❌ VolunteerProfile not found for this userId!');
            // Try finding by accountId just in case schema is different
            const volByAccount = await VolunteerProfile.findOne({ accountId: userId });
            console.log('   Checking by accountId:', volByAccount ? 'YES' : 'NO');
            return;
        }
        console.log('   VolunteerProfile ID:', volunteer._id);

        // 3. Check SosCases (History)
        console.log('\n3. Searching for History (COMPLETED/CANCELLED)...');
        const query = {
            acceptedBy: volunteer._id,
            status: { $in: ['COMPLETED', 'CANCELLED'] }
        };
        console.log('   Query:', JSON.stringify(query));

        const historyItems = await SosCase.find(query);
        console.log(`   Found ${historyItems.length} items.`);

        if (historyItems.length === 0) {
            console.log('   ❌ No history items found.');

            // Debug: Check if there are ANY cases accepted by this volunteer, regardless of status
            const allAccepted = await SosCase.find({ acceptedBy: volunteer._id });
            console.log(`   \n   Debug: Total cases accepted by this volunteer (any status): ${allAccepted.length}`);
            allAccepted.forEach(c => console.log(`      - Case ${c._id}: Status='${c.status}'`));
        } else {
            historyItems.forEach(item => {
                console.log(`   - Case ${item._id}: Status=${item.status}, CreatedAt=${item.createdAt}`);
            });
        }

    } catch (error) {
        console.error('Error:', error);
    } finally {
        await mongoose.disconnect();
    }
}

debugHistory();
