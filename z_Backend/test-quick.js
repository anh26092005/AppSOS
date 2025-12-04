/**
 * 🚀 QUICK TEST - Progressive Ban Only
 * Đơn giản nhất để test ngay
 */

const axios = require('axios');

const API_BASE = 'http://localhost:5000/api';

const TEST_USER = {
    phone: '0912345678',
    password: 'password123',
};

let token = null;

async function quickTest() {
    console.log('🧪 QUICK TEST: Progressive Ban System\n');

    try {
        // 1. Login
        console.log('Step 1: Login...');
        const loginRes = await axios.post(`${API_BASE}/auth/login`, TEST_USER);
        token = loginRes.data.token;
        console.log('✅ Login success\n');

        // 2. Send 3 SOS (all should succeed)
        for (let i = 1; i <= 3; i++) {
            console.log(`Step ${i + 1}: Send SOS #${i}...`);
            const res = await axios.post(
                `${API_BASE}/sos/cases`,
                {
                    latitude: 10.8231,
                    longitude: 106.6297,
                    emergencyType: 'MEDICAL',
                    description: `Test ${i}`,
                },
                { headers: { Authorization: `Bearer ${token}` } }
            );

            const caseId = res.data.data.case._id;
            console.log(`✅ SOS #${i} created: ${res.data.data.case.code}`);

            // Cancel immediately
            await axios.patch(
                `${API_BASE}/sos/cases/${caseId}/cancel`,
                { cancelReason: 'Test' },
                { headers: { Authorization: `Bearer ${token}` } }
            );
            console.log(`   Cancelled\n`);
        }

        // 3. Try 4th SOS (should be BANNED)
        console.log('Step 5: Try 4th SOS (should fail)...');
        try {
            await axios.post(
                `${API_BASE}/sos/cases`,
                {
                    latitude: 10.8231,
                    longitude: 106.6297,
                    emergencyType: 'MEDICAL',
                    description: 'Test 4 (should fail)',
                },
                { headers: { Authorization: `Bearer ${token}` } }
            );

            console.log('❌ TEST FAILED: 4th SOS succeeded (should be banned)\n');

        } catch (error) {
            if (error.response?.status === 429) {
                console.log('✅ BANNED! Received 429 error');
                console.log(`   Message: ${error.response.data.message}\n`);
                console.log('🎉 TEST PASSED!\n');
            } else {
                console.log(`❌ Wrong error: ${error.response?.status}\n`);
            }
        }

    } catch (error) {
        console.error('💥 Test failed:', error.response?.data || error.message);
    }
}

quickTest();
