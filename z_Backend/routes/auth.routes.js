const express = require('express');
const { register, login, logout, getProfile, updateProfile, updateAvatar, changePassword } = require('../controllers/auth.controller');
const { socialLogin } = require('../controllers/socialAuth.controller');
const { authenticate } = require('../middleware/auth');
const { uploadAvatar, handleUploadError } = require('../config/s3');

const router = express.Router();

router.post('/register', register);
router.post('/login', login);
router.post('/social-login', socialLogin);
router.get('/me', authenticate, getProfile);
router.put('/profile', authenticate, updateProfile);
router.put('/avatar', authenticate, uploadAvatar.single('avatar'), handleUploadError, updateAvatar);
router.put('/change-password', authenticate, changePassword);

// Logout
router.post('/logout', authenticate, logout);

module.exports = router;
