const mongoose = require('mongoose');
const dotenv = require('dotenv');
const { User, SosCase, SosResponderQueue, VolunteerProfile, Notification } = require('./models');
const { createSosCase, acceptSosCase, completeSosCase, getActiveSosCase } = require('./controllers/sos.controller');

dotenv.config();

// Mock Express Request/Response
const mockReq = (user, body = {}, params = {}, query = {}) => ({
    user,
    body,
    params,
    query
});

const mockRes = () => {
    const res = {};
    res.status = (code) => {
        res.statusCode = code;
        return res;
    };
    res.json = (data) => {
        res.data = data;
        return res;
    };
    return res;
};

const mockNext = (err) => {
    if (err) console.error('❌ Error:', err);
};

async function runTest() {
    try {
        console.log('🚀 Starting Full Flow Verification...');
        await mongoose.connect(process.env.MONGO_URI);
        console.log('✅ Connected to DB');

        // 1. Setup Users
        console.log('\n1️⃣ Setting up Test Users...');
        const reporter = await User.findOne({ email: 'nguoidung@test.com' });
        const volunteer = await User.findOne({ email: 'tnv@test.com' });

        if (!reporter || !volunteer) {
            throw new Error('Test users not found. Please run fix-account.js first.');
        }
        console.log(`   Reporter: ${reporter.fullName} (${reporter._id})`);
        console.log(`   Volunteer: ${volunteer.fullName} (${volunteer._id})`);

        // Ensure Volunteer Profile exists and is READY
        let volProfile = await VolunteerProfile.findOne({ userId: volunteer._id });
        if (!volProfile) {
            volProfile = await VolunteerProfile.create({
                userId: volunteer._id,
                type: 'CN',
                homeBase: { location: { type: 'Point', coordinates: [106.660172, 10.762622] } }, // HCM
                status: 'APPROVED',
                ready: true
            });
        } else {
            volProfile.status = 'APPROVED';
            volProfile.ready = true;
            volProfile.homeBase = { location: { type: 'Point', coordinates: [106.660172, 10.762622] } };
            await volProfile.save();
        }
        console.log('   Volunteer Profile: READY');

        // Cleanup old data
        // Cleanup old data
        await SosCase.deleteMany({});
        await SosResponderQueue.deleteMany({});
        await Notification.deleteMany({});
        console.log('   Cleaned up ALL old test data');

        // 2. Create SOS Case (Reporter)
        console.log('\n2️⃣ Reporter Creating SOS...');
        const createReq = mockReq(reporter, {
            latitude: 10.762622,
            longitude: 106.660172,
            emergencyType: 'ACCIDENT',
            description: 'Test Accident'
        });
        const createRes = mockRes();
        await createSosCase(createReq, createRes, mockNext);
        const sosCase = createRes.data.data.case;
        console.log(`   SOS Created: ${sosCase._id} (Status: ${sosCase.status})`);

        // 3. Volunteer Accepts SOS
        console.log('\n3️⃣ Volunteer Accepting SOS...');
        const acceptReq = mockReq(volunteer, { latitude: 10.762622, longitude: 106.660172 }, { caseId: sosCase._id.toString() });
        const acceptRes = mockRes();
        await acceptSosCase(acceptReq, acceptRes, mockNext);
        console.log(`   SOS Accepted. Status: ${acceptRes.data.data.case.status}`);

        // 4. Verify State Restoration (Routing)
        console.log('\n4️⃣ Verifying State Restoration (Routing)...');

        // Check Reporter
        const repCheckReq = mockReq(reporter);
        const repCheckRes = mockRes();
        await getActiveSosCase(repCheckReq, repCheckRes, mockNext);
        const repRole = repCheckRes.data.data.userRole;
        console.log(`   Reporter Check: Role=${repRole} (Expected: REPORTER) -> ${repRole === 'REPORTER' ? '✅ PASS' : '❌ FAIL'}`);

        // Check Volunteer
        const volCheckReq = mockReq(volunteer);
        const volCheckRes = mockRes();
        await getActiveSosCase(volCheckReq, volCheckRes, mockNext);
        const volRole = volCheckRes.data.data.userRole;
        console.log(`   Volunteer Check: Role=${volRole} (Expected: VOLUNTEER) -> ${volRole === 'VOLUNTEER' ? '✅ PASS' : '❌ FAIL'}`);

        // 5. Setup Auto-Catch Scenario (Create a 2nd pending case)
        console.log('\n5️⃣ Setting up Auto-Catch (Creating 2nd Pending SOS)...');
        // Create a dummy 2nd reporter
        const reporter2 = await User.create({
            fullName: 'Reporter 2',
            email: `rep2_${Date.now()}@test.com`,
            password: 'password',
            phone: '0999999999',
            roles: ['USER'],
            isActive: true
        });

        const createReq2 = mockReq(reporter2, {
            latitude: 10.762622,
            longitude: 106.660172,
            emergencyType: 'FIRE',
            description: 'Test Fire'
        });
        const createRes2 = mockRes();
        await createSosCase(createReq2, createRes2, mockNext);
        const sosCase2 = createRes2.data.data.case;
        console.log(`   2nd SOS Created: ${sosCase2._id} (Status: ${sosCase2.status})`);

        // 6. Volunteer Completes First SOS
        console.log('\n6️⃣ Volunteer Completing First SOS...');
        const completeReq = mockReq(volunteer, {}, { caseId: sosCase._id.toString() });
        const completeRes = mockRes();
        await completeSosCase(completeReq, completeRes, mockNext);
        console.log(`   First SOS Completed. Status: ${completeRes.data.data.case.status}`);

        // 7. Verify Auto-Catch
        console.log('\n7️⃣ Verifying Auto-Catch Logic...');
        // Check if volunteer was added to queue for 2nd case
        const queueItem = await SosResponderQueue.findOne({ sosId: sosCase2._id, volunteerId: volunteer._id });
        console.log(`   Queue Item for 2nd Case: ${queueItem ? 'FOUND' : 'NOT FOUND'} (Expected: FOUND)`);
        if (queueItem) {
            console.log(`   Queue Status: ${queueItem.status} (Expected: NOTIFIED) -> ${queueItem.status === 'NOTIFIED' ? '✅ PASS' : '❌ FAIL'}`);
        }

        // Check Notifications
        const notif = await Notification.findOne({ userId: volunteer._id, type: 'SOS_CASE', 'data.caseId': sosCase2._id.toString() });
        console.log(`   Notification Sent: ${notif ? 'YES' : 'NO'} (Expected: YES) -> ${notif ? '✅ PASS' : '❌ FAIL'}`);

        // Cleanup Reporter 2
        await User.findByIdAndDelete(reporter2._id);
        await SosCase.findByIdAndDelete(sosCase2._id);

        console.log('\n✨ ALL TESTS COMPLETED ✨');
        process.exit(0);

    } catch (error) {
        console.error('\n❌ TEST FAILED:', error);
        const fs = require('fs');
        fs.writeFileSync('error_flow.log', error.stack || error.toString());
        process.exit(1);
    }
}

runTest();
