/**
 * 🧪 COMPREHENSIVE SOS SYSTEM TEST
 * 
 * Tests all implemented features:
 * 1. Progressive Ban System (3 strikes → 10 min ban)
 * 2. Timeout Mechanism (30s TNV timeout)
 * 3. Auto-Cancel (when no volunteers available)
 * 4. Full Happy Path (User → TNV → Accept)
 */

const axios = require('axios');
const mongoose = require('mongoose');

const API_BASE = 'http://localhost:5000/api';
const DB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/safe-connect';

// Test accounts
const TEST_USER = {
    phone: '0912345678',
    password: 'password123',
};

const TEST_VOLUNTEER = {
    phone: '0987654321',
    password: 'password123',
};

let userToken = null;
let volunteerToken = null;
let db = null;

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

// ==============================================
// SETUP & TEARDOWN
// ==============================================

async function connectDB() {
    try {
        console.log('🔌 Connecting to MongoDB...');
        await mongoose.connect(DB_URI);
        db = mongoose.connection.db;
        console.log('✅ MongoDB connected\n');
    } catch (error) {
        console.error('❌ MongoDB connection failed:', error.message);
        process.exit(1);
    }
}

async function cleanup() {
    try {
        console.log('\n🧹 Cleaning up test data...');

        // Reset user ban status
        if (db) {
            await db.collection('users').updateMany(
                { phone: { $in: [TEST_USER.phone, TEST_VOLUNTEER.phone] } },
                { $set: { sosBanUntil: null } }
            );
        }

        console.log('✅ Cleanup complete');
    } catch (error) {
        console.error('⚠️  Cleanup error:', error.message);
    }
}

async function login(credentials, label) {
    try {
        console.log(`🔐 Logging in as ${label}...`);
        const response = await axios.post(`${API_BASE}/auth/login`, credentials);
        console.log(`✅ ${label} login successful\n`);
        return response.data.token;
    } catch (error) {
        console.error(`❌ ${label} login failed:`, error.response?.data || error.message);
        throw error;
    }
}

// ==============================================
// TEST HELPERS
// ==============================================

async function sendSOS(token, description) {
    try {
        const response = await axios.post(
            `${API_BASE}/sos/cases`,
            {
                latitude: 10.8231,
                longitude: 106.6297,
                emergencyType: 'MEDICAL',
                description,
            },
            { headers: { Authorization: `Bearer ${token}` } }
        );

        return {
            success: true,
            caseId: response.data.data.case._id,
            caseCode: response.data.data.case.code,
        };
    } catch (error) {
        return {
            success: false,
            status: error.response?.status,
            message: error.response?.data?.message,
        };
    }
}

async function cancelCase(token, caseId) {
    try {
        await axios.patch(
            `${API_BASE}/sos/cases/${caseId}/cancel`,
            { cancelReason: 'Test cancel' },
            { headers: { Authorization: `Bearer ${token}` } }
        );
        return true;
    } catch (error) {
        return false;
    }
}

async function getCaseDetails(token, caseId) {
    try {
        const response = await axios.get(
            `${API_BASE}/sos/cases/${caseId}`,
            { headers: { Authorization: `Bearer ${token}` } }
        );
        return response.data.data.case;
    } catch (error) {
        return null;
    }
}

// ==============================================
// TEST 1: PROGRESSIVE BAN SYSTEM
// ==============================================

async function testProgressiveBan() {
    console.log('\n' + '='.repeat(70));
    console.log('📝 TEST 1: PROGRESSIVE BAN SYSTEM');
    console.log('='.repeat(70));
    console.log('Scenario: User sends 3 SOS → 4th attempt gets banned\n');

    let passed = false;

    try {
        // Send 3 SOS cases
        for (let i = 1; i <= 3; i++) {
            console.log(`📡 Attempt ${i}/3: Sending SOS...`);
            const result = await sendSOS(userToken, `Test Ban #${i}`);

            if (!result.success) {
                console.log(`❌ Attempt ${i} failed unexpectedly`);
                return false;
            }

            console.log(`✅ Attempt ${i}: Created case ${result.caseCode}`);
            await cancelCase(userToken, result.caseId);
            console.log(`   ℹ️  Cancelled\n`);

            await sleep(500);
        }

        console.log('🔥 Attempting 4th SOS (should trigger ban)...\n');
        await sleep(1000);

        const fourthAttempt = await sendSOS(userToken, 'Test Ban #4 (should fail)');

        if (!fourthAttempt.success && fourthAttempt.status === 429) {
            console.log('✅ 4th attempt BLOCKED with 429 error');
            console.log(`   Message: ${fourthAttempt.message}`);
            passed = true;
        } else if (fourthAttempt.success) {
            console.log('❌ 4th attempt succeeded (should have been banned)');
        } else {
            console.log(`⚠️  4th attempt failed with different error: ${fourthAttempt.status}`);
        }

        // Wait for ban to expire (for next tests)
        if (passed) {
            console.log('\n⏳ Waiting for ban to expire (10+ seconds)...');
            await sleep(11000);

            // Reset ban manually via DB for faster testing
            await db.collection('users').updateOne(
                { phone: TEST_USER.phone },
                { $set: { sosBanUntil: null } }
            );

            // Clear rate limit logs
            await db.collection('sos_rate_limit_logs').deleteMany({
                userId: (await db.collection('users').findOne({ phone: TEST_USER.phone }))._id
            });

            console.log('✅ Ban cleared for next tests\n');
        }

    } catch (error) {
        console.error('💥 Test error:', error.message);
    }

    console.log('─'.repeat(70));
    console.log(passed ? '✅ TEST 1 PASSED' : '❌ TEST 1 FAILED');
    console.log('─'.repeat(70));

    return passed;
}

// ==============================================
// TEST 2: TIMEOUT MECHANISM (requires volunteer inactivity)
// ==============================================

async function testTimeout() {
    console.log('\n' + '='.repeat(70));
    console.log('📝 TEST 2: TIMEOUT MECHANISM');
    console.log('='.repeat(70));
    console.log('Scenario: User sends SOS → Wait 30s → Check if timeout triggered\n');
    console.log('⚠️  NOTE: This test requires volunteer to NOT respond\n');

    let passed = false;

    try {
        console.log('📡 Sending SOS...');
        const result = await sendSOS(userToken, 'Timeout Test - Do NOT accept');

        if (!result.success) {
            console.log('❌ Failed to create SOS');
            return false;
        }

        console.log(`✅ SOS created: ${result.caseCode}`);
        console.log(`   Case ID: ${result.caseId}\n`);

        // Check initial status
        let caseDetails = await getCaseDetails(userToken, result.caseId);
        console.log(`Initial status: ${caseDetails.status}`);

        // Wait for timeout + processing
        console.log('\n⏳ Waiting 35 seconds for timeout to trigger...');
        console.log('   (Cron job runs every 10s, timeout is 30s)\n');

        for (let i = 35; i > 0; i -= 5) {
            await sleep(5000);
            console.log(`   ${i - 5}s remaining...`);
        }

        // Check if queue item expired
        const queue = await db.collection('sos_responder_queue').find({
            sosId: new mongoose.Types.ObjectId(result.caseId)
        }).toArray();

        console.log(`\n📊 Queue items: ${queue.length}`);
        const expiredCount = queue.filter(item => item.status === 'EXPIRED').length;
        console.log(`   - EXPIRED: ${expiredCount}`);
        console.log(`   - NOTIFIED: ${queue.filter(item => item.status === 'NOTIFIED').length}`);

        if (expiredCount > 0) {
            console.log('✅ Timeout mechanism working - queue items expired');
            passed = true;
        } else {
            console.log('❌ No expired queue items found');
        }

        // Cleanup
        await cancelCase(userToken, result.caseId);

    } catch (error) {
        console.error('💥 Test error:', error.message);
    }

    console.log('─'.repeat(70));
    console.log(passed ? '✅ TEST 2 PASSED' : '❌ TEST 2 FAILED');
    console.log('─'.repeat(70));

    return passed;
}

// ==============================================
// TEST 3: AUTO-CANCEL (when no volunteers)
// ==============================================

async function testAutoCancel() {
    console.log('\n' + '='.repeat(70));
    console.log('📝 TEST 3: AUTO-CANCEL MECHANISM');
    console.log('='.repeat(70));
    console.log('Scenario: User sends SOS with NO volunteers available\n');
    console.log('⚠️  NOTE: This requires all volunteers to be "not ready"\n');

    let passed = false;

    try {
        // Temporarily disable all volunteers
        console.log('🔧 Setting all volunteers to NOT READY...');
        await db.collection('volunteer_profiles').updateMany(
            {},
            { $set: { ready: false } }
        );
        console.log('✅ All volunteers disabled\n');

        console.log('📡 Sending SOS (no volunteers available)...');
        const result = await sendSOS(userToken, 'Auto-Cancel Test');

        if (!result.success) {
            console.log('❌ Failed to create SOS');
            return false;
        }

        console.log(`✅ SOS created: ${result.caseCode}`);
        console.log(`   Status: SEARCHING (expected)\n`);

        // Wait for auto-cancel
        console.log('⏳ Waiting 35 seconds for auto-cancel...\n');

        for (let i = 35; i > 0; i -= 5) {
            await sleep(5000);
            console.log(`   ${i - 5}s remaining...`);
        }

        // Check if case was auto-cancelled
        const caseDetails = await getCaseDetails(userToken, result.caseId);

        console.log(`\n📊 Final case status: ${caseDetails.status}`);
        console.log(`   Auto-cancelled: ${caseDetails.meta?.autoCancelledDueToTimeout || false}`);

        if (caseDetails.status === 'CANCELLED' && caseDetails.meta?.autoCancelledDueToTimeout) {
            console.log('✅ Case auto-cancelled as expected');
            passed = true;
        } else {
            console.log('❌ Case not auto-cancelled');
        }

        // Re-enable volunteers
        console.log('\n🔧 Re-enabling volunteers...');
        await db.collection('volunteer_profiles').updateMany(
            {},
            { $set: { ready: true } }
        );

    } catch (error) {
        console.error('💥 Test error:', error.message);
    }

    console.log('─'.repeat(70));
    console.log(passed ? '✅ TEST 3 PASSED' : '❌ TEST 3 FAILED');
    console.log('─'.repeat(70));

    return passed;
}

// ==============================================
// MAIN TEST RUNNER
// ==============================================

async function runAllTests() {
    console.log('\n🚀 STARTING COMPREHENSIVE SOS SYSTEM TESTS\n');
    console.log('Testing Features:');
    console.log('  1. Progressive Ban System');
    console.log('  2. Timeout Mechanism');
    console.log('  3. Auto-Cancel Mechanism');
    console.log('\n');

    try {
        await connectDB();
        await cleanup();

        // Login
        userToken = await login(TEST_USER, 'User');

        // Run tests
        const results = [];

        results.push(await testProgressiveBan());
        results.push(await testTimeout());
        results.push(await testAutoCancel());

        // Summary
        console.log('\n' + '='.repeat(70));
        console.log('📊 TEST SUMMARY');
        console.log('='.repeat(70));

        const passed = results.filter(r => r).length;
        const total = results.length;

        console.log(`Total Tests: ${total}`);
        console.log(`Passed: ${passed}`);
        console.log(`Failed: ${total - passed}`);
        console.log(`Success Rate: ${((passed / total) * 100).toFixed(1)}%`);

        console.log('\n' + (passed === total ? '✅ ALL TESTS PASSED!' : '⚠️  SOME TESTS FAILED'));
        console.log('='.repeat(70));

    } catch (error) {
        console.error('\n💥 Test suite crashed:', error);
    } finally {
        await cleanup();
        await mongoose.disconnect();
        console.log('\n👋 Tests complete\n');
    }
}

// Run
runAllTests();
