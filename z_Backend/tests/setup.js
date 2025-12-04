// Test setup file
require('dotenv').config({ path: '.env' });

// Set test environment variables
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-secret-key';

// Mock Firebase Admin for tests
jest.mock('firebase-admin', () => ({
    initializeApp: jest.fn(),
    credential: {
        cert: jest.fn()
    },
    messaging: jest.fn(() => ({
        send: jest.fn().mockResolvedValue('message-id'),
        sendMulticast: jest.fn().mockResolvedValue({ successCount: 1, failureCount: 0 })
    }))
}));

console.log('✅ Test environment setup complete');
