const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../server');
const { VolunteerProfile, User, SosCase } = require('../models');

describe('Volunteer Controller Tests', () => {
    let authToken;
    let volunteerId;
    let userId;

    beforeAll(async () => {
        // Connect to test database
        await mongoose.connect(process.env.MONGODB_URI_TEST || process.env.MONGODB_URI);
    });

    afterAll(async () => {
        // Clean up and close connection
        await mongoose.connection.close();
    });

    describe('POST /api/volunteers/me/toggle-ready', () => {
        beforeEach(async () => {
            // Create test user and volunteer profile
            const testUser = await User.create({
                fullName: 'Test Volunteer',
                email: `test${Date.now()}@example.com`,
                phone: `099${Math.floor(Math.random() * 10000000)}`,
                password: 'password123',
                roles: ['TNV_CN'],
                isActive: true
            });

            userId = testUser._id;

            const testVolunteer = await VolunteerProfile.create({
                userId: testUser._id,
                type: 'CN',
                homeBase: {
                    location: {
                        type: 'Point',
                        coordinates: [106.6500, 10.8500] // HCM City
                    },
                    radiusKm: 5
                },
                status: 'APPROVED',
                ready: false
            });

            volunteerId = testVolunteer._id;

            // Login to get token
            const loginRes = await request(app)
                .post('/api/auth/login')
                .send({
                    email: testUser.email,
                    password: 'password123'
                });

            authToken = loginRes.body.token;
        });

        afterEach(async () => {
            // Clean up test data
            await VolunteerProfile.deleteMany({ userId });
            await User.deleteMany({ _id: userId });
        });

        it('should toggle ready status from false to true', async () => {
            const res = await request(app)
                .patch('/api/volunteers/me/toggle-ready')
                .set('Authorization', `Bearer ${authToken}`)
                .expect(200);

            expect(res.body.success).toBe(true);
            expect(res.body.data.ready).toBe(true);
            expect(res.body.message).toContain('ACTIVE');
        });

        it('should toggle ready status from true to false', async () => {
            // First, set ready to true
            await VolunteerProfile.findByIdAndUpdate(volunteerId, { ready: true });

            const res = await request(app)
                .patch('/api/volunteers/me/toggle-ready')
                .set('Authorization', `Bearer ${authToken}`)
                .expect(200);

            expect(res.body.success).toBe(true);
            expect(res.body.data.ready).toBe(false);
            expect(res.body.message).toContain('INACTIVE');
        });

        it('should fail without authentication', async () => {
            const res = await request(app)
                .patch('/api/volunteers/me/toggle-ready')
                .expect(401);

            expect(res.body.success).toBe(false);
        });

        it('should fail for non-volunteer users', async () => {
            // Create non-volunteer user
            const regularUser = await User.create({
                fullName: 'Regular User',
                email: `regular${Date.now()}@example.com`,
                phone: `098${Math.floor(Math.random() * 10000000)}`,
                password: 'password123',
                roles: ['USER'],
                isActive: true
            });

            const loginRes = await request(app)
                .post('/api/auth/login')
                .send({
                    email: regularUser.email,
                    password: 'password123'
                });

            const res = await request(app)
                .patch('/api/volunteers/me/toggle-ready')
                .set('Authorization', `Bearer ${loginRes.body.token}`)
                .expect(403);

            expect(res.body.success).toBe(false);
            expect(res.body.message).toContain('Only volunteers');

            // Clean up
            await User.deleteOne({ _id: regularUser._id });
        });
    });

    describe('GET /api/volunteers/me', () => {
        it('should fetch volunteer profile', async () => {
            // This test requires a logged-in volunteer
            // Implementation depends on your fetchMyVolunteerProfile endpoint
        });
    });
});
