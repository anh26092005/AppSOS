/**
 * Test Script: Progressive Ban System
 * 
 * Test Case: Spam 3 lần trong 10 phút → Bị ban
 * Expected: Lần thử thứ 4 sẽ nhận error 429
 */

const axios = require('axios');

const API_BASE = 'http://localhost:5000/api';
let authToken = null;

// Test user credentials
const TEST_USER = {
    phone: '0912345678',
    password: 'password123',
};

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function login() {
    try {
        console.log('🔐 Logging in...');
        const response = await axios.post(`${API_BASE}/auth/login`, TEST_USER);
        authToken = response.data.token;
        console.log('✅ Login successful\n');
        return true;
    } catch (error) {
        console.error('❌ Login failed:', error.response?.data || error.message);
        return false;
    }
}

async function sendSOS(attemptNumber) {
    try {
        console.log(`📡 Attempt #${attemptNumber}: Sending SOS...`);

        const response = await axios.post(
            `${API_BASE}/sos/cases`,
            {
                latitude: 10.8231,
                longitude: 106.6297,
                emergencyType: 'MEDICAL',
                description: `Test SOS #${attemptNumber}`,
            },
            {
                headers: { Authorization: `Bearer ${authToken}` },
            }
        );

        console.log(`✅ Attempt #${attemptNumber}: SOS created successfully`);
        console.log(`   Case Code: ${response.data.data.case.code}\n`);

        return { success: true, caseId: response.data.data.case._id };
    } catch (error) {
        if (error.response?.status === 429) {
            console.log(`🚫 Attempt #${attemptNumber}: BANNED!`);
            console.log(`   Message: ${error.response.data.message}\n`);
            return { success: false, banned: true };
        } else {
            console.error(`❌ Attempt #${attemptNumber}: Failed`);
            console.error(`   Error: ${error.response?.data?.message || error.message}\n`);
            return { success: false, banned: false };
        }
    }
}

async function cancelCase(caseId) {
    try {
        await axios.patch(
            `${API_BASE}/sos/cases/${caseId}/cancel`,
            { cancelReason: 'Test cancel' },
            { headers: { Authorization: `Bearer ${authToken}` } }
        );
        console.log(`   ℹ️  Case cancelled\n`);
    } catch (error) {
        console.error(`   ⚠️  Could not cancel case: ${error.message}\n`);
    }
}

async function runTest() {
    console.log('='.repeat(60));
    console.log('🧪 TEST: PROGRESSIVE BAN SYSTEM');
    console.log('='.repeat(60));
    console.log('Scenario: User spams 3 times → Gets banned on 4th attempt\n');

    // Step 1: Login
    if (!(await login())) {
        console.log('\n❌ Cannot proceed without login');
        return;
    }

    // Step 2: Send SOS 3 times (should all succeed)
    const caseIds = [];

    for (let i = 1; i <= 3; i++) {
        const result = await sendSOS(i);
        if (result.success) {
            caseIds.push(result.caseId);
            // Cancel to clean up
            await cancelCase(result.caseId);
        } else if (result.banned) {
            console.log('⚠️  Unexpected: Got banned before 4th attempt!');
            return;
        }

        await sleep(500); // Small delay
    }

    console.log('ℹ️  User has sent 3 SOS cases in the last 10 minutes\n');
    await sleep(1000);

    // Step 3: Try 4th time (should be BANNED)
    console.log('🔥 Now attempting 4th SOS (should trigger ban)...\n');
    const fourthAttempt = await sendSOS(4);

    // Verify result
    console.log('='.repeat(60));
    console.log('📊 TEST RESULT');
    console.log('='.repeat(60));

    if (fourthAttempt.banned) {
        console.log('✅ TEST PASSED!');
        console.log('   - User successfully banned after 3 spam attempts');
        console.log('   - Received 429 error as expected');
    } else if (fourthAttempt.success) {
        console.log('❌ TEST FAILED!');
        console.log('   - 4th attempt succeeded (should have been banned)');
    } else {
        console.log('⚠️  TEST INCONCLUSIVE');
        console.log('   - 4th attempt failed for different reason');
    }

    console.log('='.repeat(60));
}

// Run test
runTest().catch((error) => {
    console.error('\n💥 Test crashed:', error);
    process.exit(1);
});
