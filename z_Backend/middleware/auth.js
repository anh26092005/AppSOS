const AppError = require('../utils/appError');
const { verifyToken } = require('../utils/jwt');
const { User } = require('../models');

const extractBearerToken = (req) => {
  const header = req.headers.authorization || '';
  if (header.startsWith('Bearer ')) {
    return header.substring(7);
  }
  if (req.cookies?.token) {
    return req.cookies.token;
  }
  return null;
};

const authenticate = async (req, res, next) => {
  try {
    const token = extractBearerToken(req);
    if (!token) {
      throw new AppError('Authentication required', 401);
    }

    const payload = verifyToken(token);
    console.log('Auth Debug - Payload:', payload);
    const userId = payload.sub || payload.id || payload._id;
    console.log('Auth Debug - UserId:', userId);
    const user = await User.findById(userId).lean();

    if (!user) {
      throw new AppError('User not found', 401);
    }

    if (user.isActive === false) {
      throw new AppError('Account is deactivated', 403);
    }

    req.user = user;
    req.auth = { token, payload };
    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
      next(new AppError('Invalid or expired token', 401));
    } else {
      next(error);
    }
  }
};

// Middleware xác thực tùy chọn - không bắt buộc phải có token
// Nếu có token hợp lệ thì set req.user, nếu không có thì vẫn cho phép request tiếp tục
const authenticateOptional = async (req, res, next) => {
  try {
    const token = extractBearerToken(req);
    if (!token) {
      // Không có token, nhưng vẫn cho phép tiếp tục
      return next();
    }

    const payload = verifyToken(token);
    const userId = payload.sub || payload.id || payload._id;
    const user = await User.findById(userId).lean();

    if (!user || user.isActive === false) {
      // Token không hợp lệ hoặc user bị deactivate, nhưng vẫn cho phép tiếp tục
      return next();
    }

    // Set user vào request nếu token hợp lệ
    req.user = user;
    req.auth = { token, payload };
    next();
  } catch (error) {
    // Có lỗi khi verify token nhưng vẫn cho phép request tiếp tục
    next();
  }
};

const authorize =
  (...allowedRoles) =>
  (req, res, next) => {
    if (!req.user) {
      return next(new AppError('Authentication required', 401));
    }

    if (allowedRoles.length === 0) {
      return next();
    }

    const userRoles = req.user.roles || [];
    const isAllowed = allowedRoles.some((role) => userRoles.includes(role));
    if (!isAllowed) {
      return next(new AppError('Forbidden', 403));
    }

    return next();
  };

module.exports = {
  authenticate,
  authenticateOptional,
  authorize,
};
