const mongoose = require('mongoose');
const dotenv = require('dotenv');
const { User, Device } = require('./models');
const bcrypt = require('bcryptjs');

dotenv.config();

async function createTestUsers() {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('Connected to MongoDB');

        // 1. Create Reporter
        let reporter = await User.findOne({ email: 'nguoidung@test.com' });
        if (!reporter) {
            const hashedPassword = await bcrypt.hash('123456', 10);
            reporter = await User.create({
                fullName: 'Người Dùng Test',
                email: 'nguoidung@test.com',
                password: hashedPassword,
                phone: '0901234567',
                roles: ['USER'],
                isActive: true
            });
            console.log('✅ Created Reporter: nguoidung@test.com');
        } else {
            console.log('ℹ️ Reporter already exists');
        }

        // 2. Create Volunteer
        let volunteer = await User.findOne({ email: 'tnv@test.com' });
        if (!volunteer) {
            const hashedPassword = await bcrypt.hash('123456', 10);
            volunteer = await User.create({
                fullName: 'Tình Nguyện Viên Test',
                email: 'tnv@test.com',
                password: hashedPassword,
                phone: '0909876543',
                roles: ['TNV_CN', 'USER'],
                isActive: true
            });
            console.log('✅ Created Volunteer: tnv@test.com');

            // Create dummy device for FCM
            await Device.create({
                userId: volunteer._id,
                deviceId: 'test-device-id',
                pushToken: 'test-push-token',
                platform: 'ANDROID'
            });
            console.log('✅ Created Dummy Device for Volunteer');
        } else {
            console.log('ℹ️ Volunteer already exists');
            // Ensure device exists
            const device = await Device.findOne({ userId: volunteer._id });
            if (!device) {
                await Device.create({
                    userId: volunteer._id,
                    deviceId: 'test-device-id',
                    pushToken: 'test-push-token',
                    platform: 'ANDROID'
                });
                console.log('✅ Created Dummy Device for Volunteer (Existing User)');
            }
        }

        process.exit(0);
    } catch (error) {
        console.error('❌ Error:', error);
        if (error.errors) {
            console.error('Validation Errors:', JSON.stringify(error.errors, null, 2));
        }
        process.exit(1);
    }
}

createTestUsers();
