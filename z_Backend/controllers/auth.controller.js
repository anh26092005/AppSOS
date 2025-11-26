const bcrypt = require('bcryptjs');
const AppError = require('../utils/appError');
const { signAccessToken } = require('../utils/jwt');
const { User, VolunteerProfile } = require('../models');

// ... (giữ nguyên phần đầu)

const getProfile = async (req, res, next) => {
  try {
    if (!req.user?._id) {
      throw new AppError('Authentication required', 401);
    }

    const freshUser = await User.findById(req.user._id).lean();
    if (!freshUser) {
      throw new AppError('User not found', 404);
    }

    const userResponse = buildUserResponse(freshUser);

    // Check volunteer profile status
    const volunteerProfile = await VolunteerProfile.findOne({ userId: freshUser._id }).lean();
    if (volunteerProfile) {
      userResponse.volunteerStatus = volunteerProfile.status; // PENDING, APPROVED, REJECTED
      userResponse.volunteerId = volunteerProfile._id;
    }

    res.json({ user: userResponse });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  register,
  login,
  getProfile,
};
