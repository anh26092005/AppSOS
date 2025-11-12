const { Device } = require('../models');
const AppError = require('../utils/appError');

/**
 * Đăng ký/cập nhật device token
 * POST /api/devices/register
 * Body: { pushToken (required), platform (required: 'ANDROID'|'IOS'), latitude, longitude }
 */
const registerDevice = async (req, res, next) => {
  try {
    const { pushToken, platform, latitude, longitude } = req.body;
    const userId = req.user._id;

    // Validate required fields
    if (!pushToken || !platform) {
      throw new AppError('Push token and platform are required', 400);
    }

    // Validate platform
    if (!['ANDROID', 'IOS'].includes(platform)) {
      throw new AppError('Platform must be ANDROID or IOS', 400);
    }

    // Prepare device data
    const deviceData = {
      userId,
      platform,
      pushToken,
      lastSeenAt: new Date(),
    };

    // Thêm location nếu có
    if (latitude !== undefined && longitude !== undefined) {
      // Validate coordinates
      const lat = parseFloat(latitude);
      const lng = parseFloat(longitude);

      if (isNaN(lat) || isNaN(lng)) {
        throw new AppError('Invalid coordinates format', 400);
      }

      if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
        throw new AppError('Coordinates out of range', 400);
      }

      deviceData.lastLocation = {
        type: 'Point',
        coordinates: [lng, lat], // GeoJSON format: [longitude, latitude]
      };
    }

    // Upsert device (tạo mới hoặc cập nhật nếu đã tồn tại)
    const device = await Device.findOneAndUpdate(
      { userId, pushToken },
      deviceData,
      { upsert: true, new: true }
    );

    res.json({
      success: true,
      data: device,
      message: 'Device registered successfully',
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Xóa device token
 * POST /api/devices/unregister
 * Body: { pushToken (required) }
 */
const unregisterDevice = async (req, res, next) => {
  try {
    const { pushToken } = req.body;
    const userId = req.user._id;

    // Validate required fields
    if (!pushToken) {
      throw new AppError('Push token is required', 400);
    }

    // Xóa device
    const result = await Device.findOneAndDelete({ userId, pushToken });

    if (!result) {
      throw new AppError('Device not found', 404);
    }

    res.json({
      success: true,
      message: 'Device unregistered successfully',
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Lấy danh sách devices của user hiện tại
 * GET /api/devices
 */
const getMyDevices = async (req, res, next) => {
  try {
    const userId = req.user._id;

    const devices = await Device.find({ userId }).lean();

    res.json({
      success: true,
      data: devices,
      count: devices.length,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  registerDevice,
  unregisterDevice,
  getMyDevices,
};

