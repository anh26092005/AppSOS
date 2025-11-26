const bcrypt = require('bcryptjs');
const AppError = require('../utils/appError');
const { signAccessToken } = require('../utils/jwt');
const { User, VolunteerProfile } = require('../models');

const buildUserResponse = (user) => {
  return {
    _id: user._id,
    fullName: user.fullName,
    email: user.email,
    phone: user.phone,
    roles: user.roles,
    avatar: user.avatar,
    address: user.address,
  };
};

const register = async (req, res, next) => {
  try {
    const { fullName, phone, email, password } = req.body;

    // Check if user exists
    const query = [];
    if (phone) query.push({ phone });
    if (email) query.push({ email });

    if (query.length > 0) {
      const existingUser = await User.findOne({ $or: query });
      if (existingUser) {
        if (existingUser.phone === phone) {
          throw new AppError('Phone number already exists', 400);
        }
        if (email && existingUser.email === email) {
          throw new AppError('Email already exists', 400);
        }
      }
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    // Create user
    const newUser = await User.create({
      fullName,
      phone,
      email,
      passwordHash,
      roles: ['USER'],
    });

    // Generate token
    const token = signAccessToken({ id: newUser._id, roles: newUser.roles });

    res.status(201).json({
      success: true,
      token,
      user: buildUserResponse(newUser),
    });
  } catch (error) {
    next(error);
  }
};

const login = async (req, res, next) => {
  try {
    const { phone, email, password } = req.body;

    if (!password) {
      throw new AppError('Password is required', 400);
    }

    if (!phone && !email) {
      throw new AppError('Phone or email is required', 400);
    }

    // Find user
    const query = {};
    if (phone) query.phone = phone;
    else if (email) query.email = email;

    const user = await User.findOne(query).select('+passwordHash');

    if (!user) {
      throw new AppError('Invalid credentials', 401);
    }

    // Check password
    const isMatch = await bcrypt.compare(password, user.passwordHash);
    if (!isMatch) {
      throw new AppError('Invalid credentials', 401);
    }

    // Generate token
    const token = signAccessToken({ id: user._id, roles: user.roles });

    res.json({
      success: true,
      token,
      user: buildUserResponse(user),
    });
  } catch (error) {
    next(error);
  }
};

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
