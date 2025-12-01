const fetch = require('node-fetch'); // Or use global fetch if Node 18+

const BASE_URL = 'http://localhost:5000/api';
const EMAIL = 'user2@example.com';
const PASSWORD = 'password123';

async function testQueue() {
    try {
        // 1. Login
        console.log('Logging in...');
        const loginRes = await fetch(`${BASE_URL}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email: EMAIL, password: PASSWORD })
        });

        const loginData = await loginRes.json();
        if (!loginRes.ok) throw new Error(loginData.message || 'Login failed');

        const token = loginData.token;
        console.log('✅ Login successful. Token obtained.');

        // 2. Get Queue (Before Clear)
        console.log('\nFetching Queue (Before Clear)...');
        const getRes1 = await fetch(`${BASE_URL}/volunteers/queue`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        const getData1 = await getRes1.json();
        console.log('Queue Items:', getData1.data?.length || 0);
        if (getData1.data && getData1.data.length > 0) {
            console.log('First item:', JSON.stringify(getData1.data[0], null, 2));
        }

        // 3. Clear Queue
        console.log('\nClearing Queue...');
        const clearRes = await fetch(`${BASE_URL}/volunteers/queue`, {
            method: 'DELETE',
            headers: { 'Authorization': `Bearer ${token}` }
        });
        const clearData = await clearRes.json();
        console.log('Clear Response:', clearData);

        // 4. Get Queue (After Clear)
        console.log('\nFetching Queue (After Clear)...');
        const getRes2 = await fetch(`${BASE_URL}/volunteers/queue`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        const getData2 = await getRes2.json();
        console.log('Queue Items:', getData2.data?.length || 0);

        // Check if queue items (status NOTIFIED/DECLINED) are gone
        // Note: HISTORY items (COMPLETED/CANCELLED) should remain if any
        const remainingQueueItems = getData2.data?.filter(item => item.type === 'QUEUE');
        if (remainingQueueItems && remainingQueueItems.length === 0) {
            console.log('✅ Queue cleared successfully (QUEUE items are 0).');
        } else {
            console.log('⚠️ Queue might not be fully cleared or empty to begin with.');
        }

    } catch (error) {
        console.error('❌ Error:', error.message);
    }
}

testQueue();
