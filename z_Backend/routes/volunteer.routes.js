const express = require('express');
const {
  createVolunteerProfile,
  getVolunteers,
  getVolunteerById,
  getVolunteerByUserId,
  approveVolunteer,
  rejectVolunteer,
  updateVolunteer,
  toggleVolunteerReady,
  clearQueue,
  getQueue,
} = require('../controllers/volunteer.controller');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();

// Tạo volunteer profile (cần authentication nhưng không cần admin)
router.post('/', authenticate, createVolunteerProfile);

// Toggle ready status (TNV tự toggle, không cần admin)
router.patch('/me/toggle-ready', authenticate, toggleVolunteerReady);

// Clear queue (delete pending/declined requests)
router.delete('/queue', authenticate, clearQueue);

// Get queue and history
router.get('/queue', authenticate, getQueue);

// Lấy chi tiết volunteer theo userId (cho user thường xem profile TNV)
router.get('/user/:userId', authenticate, getVolunteerByUserId);

// Các routes còn lại cần authentication và admin authorization
// Note: We need to be careful with middleware order. 
// Routes below this line require ADMIN role.

// Lấy danh sách volunteers (Admin only)
router.get('/', authenticate, authorize('ADMIN'), getVolunteers);

// Lấy chi tiết volunteer (Admin only)
router.get('/:id', authenticate, authorize('ADMIN'), getVolunteerById);

// Phê duyệt volunteer (Admin only)
router.post('/:id/approve', authenticate, authorize('ADMIN'), approveVolunteer);

// Từ chối volunteer (Admin only)
router.post('/:id/reject', authenticate, authorize('ADMIN'), rejectVolunteer);

// Cập nhật volunteer (Admin only)
router.put('/:id', authenticate, authorize('ADMIN'), updateVolunteer);

module.exports = router;
