const express = require('express');
const {
  createVolunteerProfile,
  getVolunteers,
  getVolunteerById,
  approveVolunteer,
  rejectVolunteer,
  updateVolunteer,
} = require('../controllers/volunteer.controller');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();

// Tạo volunteer profile (cần authentication nhưng không cần admin)
router.post('/', authenticate, createVolunteerProfile);

// Các routes còn lại cần authentication và admin authorization
router.use(authenticate);
router.use(authorize('ADMIN'));

// Lấy danh sách volunteers
router.get('/', getVolunteers);

// Lấy chi tiết volunteer
router.get('/:id', getVolunteerById);

// Phê duyệt volunteer
router.post('/:id/approve', approveVolunteer);

// Từ chối volunteer
router.post('/:id/reject', rejectVolunteer);

// Cập nhật volunteer
router.put('/:id', updateVolunteer);

module.exports = router;

