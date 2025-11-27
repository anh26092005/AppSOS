const express = require('express');
const { register, login, getProfile } = require('../controllers/auth.controller');
const { socialLogin } = require('../controllers/socialAuth.controller');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

router.post('/register', register);
router.post('/login', login);
router.post('/social-login', socialLogin);
router.get('/me', authenticate, getProfile);

module.exports = router;
