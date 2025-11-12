const express = require('express');
const { registerDevice, unregisterDevice, getMyDevices } = require('../controllers/device.controller');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// Đăng ký device token
router.post('/register', authenticate, registerDevice);

// Xóa device token
router.post('/unregister', authenticate, unregisterDevice);

// Lấy danh sách devices của user
router.get('/', authenticate, getMyDevices);

module.exports = router;

