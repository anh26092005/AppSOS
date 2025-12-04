const mongoose = require('mongoose');
require('dotenv').config();

async function debugCase() {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('Connected to MongoDB\n');

        const SosCase = require('./models/sosCase.model');
        const SosResponderQueue = require('./models/sosResponderQueue.model');

        const caseId = '6931205c35f9c07d2a0cfa6e';

        // 1. Check case
        const caseData = await SosCase.findById(caseId);
        console.log('=== CASE INFO ===');
        console.log('Status:', caseData?.status);
        console.log('Code:', caseData?.code);
        console.log('CreatedAt:', caseData?.createdAt);
        console.log('Meta:', caseData?.meta);

        // 2. Check queue
        const queue = await SosResponderQueue.find({ sosId: caseId });
        console.log('\n=== QUEUE INFO ===');
        console.log('Total Queue Items:', queue.length);

        const now = new Date();
        queue.forEach((q, idx) => {
            const ageSeconds = Math.floor((now - q.notifiedAt) / 1000);
            console.log(`\n  [${idx + 1}] Status: ${q.status}`);
            console.log(`      NotifiedAt: ${q.notifiedAt}`);
            console.log(`      Age: ${ageSeconds}s ago`);
            console.log(`      VolunteerId: ${q.volunteerId}`);
        });

        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

debugCase();
