const { SystemSettings } = require('../models');
const AppError = require('../utils/appError');

/**
 * Middleware to check demo mode restrictions
 * When demo mode is enabled, only users with isDemoAllowed=true can access SOS APIs
 */
const checkDemoMode = async (req, res, next) => {
  try {
    // Get system settings from database
    const settings = await SystemSettings.getSettings();

    // If demo mode is disabled, allow all users
    if (!settings.demoMode) {
      return next();
    }

    // Demo mode is enabled - check user permissions
    const user = req.user; // Set by authenticate middleware

    // Admin users always have access
    if (user.roles && user.roles.includes('ADMIN')) {
      return next();
    }

    // Check if user has demo access
    if (!user.isDemoAllowed) {
      throw new AppError(
        'Chúng mình đang demo nên những acc được cấp phép mới được request nhé. Bạn thông cảm!',
        403
      );
    }

    // User has demo access, proceed
    next();
  } catch (error) {
    next(error);
  }
};

module.exports = { checkDemoMode };
