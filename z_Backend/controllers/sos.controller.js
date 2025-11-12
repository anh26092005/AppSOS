const { SosCase, SosResponderQueue, VolunteerProfile, User } = require('../models');
const AppError = require('../utils/appError');
const mongoose = require('mongoose');
const { sendNotificationToUser } = require('../services/fcm.service');

// Helper function: Tìm SOS case theo code hoặc ObjectId
const findSosCaseByIdOrCode = async (identifier) => {
  if (!identifier) {
    return null;
  }

  // Kiểm tra xem có phải là ObjectId hợp lệ (24 hex characters)
  const isObjectId = /^[0-9a-fA-F]{24}$/.test(String(identifier));
  
  // Luôn thử tìm theo code trước (vì code có thể có format giống ObjectId)
  const caseByCode = await SosCase.findOne({ code: String(identifier) });
  if (caseByCode) {
    return caseByCode;
  }
  
  // Nếu là ObjectId hợp lệ và không tìm thấy theo code, thử tìm theo ObjectId
  if (isObjectId) {
    try {
      const caseById = await SosCase.findById(identifier);
      if (caseById) {
        return caseById;
      }
    } catch (error) {
      // Nếu có lỗi khi tìm theo ObjectId, return null
      return null;
    }
  }
  
  return null;
};

// Helper function: Tạo Google Maps directions URL
const getDirectionsUrl = (reporterLocation, responderLocation) => {
  if (!reporterLocation || !responderLocation) {
    return null;
  }

  // Extract coordinates từ GeoJSON Point
  // Format: { type: 'Point', coordinates: [longitude, latitude] }
  const originLat = reporterLocation.coordinates[1];
  const originLng = reporterLocation.coordinates[0];
  const destLat = responderLocation.coordinates[1];
  const destLng = responderLocation.coordinates[0];

  return `https://www.google.com/maps/dir/?api=1&origin=${originLat},${originLng}&destination=${destLat},${destLng}&travelmode=driving`;
};

// Tìm TNV gần nhất trong bán kính
const findAndNotifyNearestVolunteers = async (sosCase) => {
  const { location } = sosCase;
  const maxRadius = 50; // km
  const maxVolunteers = 10;

  try {
    // Tìm các TNV đang bận (có case ACCEPTED hoặc IN_PROGRESS)
    const busyVolunteers = await SosCase.find({
      status: { $in: ['ACCEPTED', 'IN_PROGRESS'] },
      acceptedBy: { $ne: null },
    }).distinct('acceptedBy');

    // Tìm TNV trong bán kính, không bận, đã approved và ready
    // Sử dụng $geoNear làm stage đầu tiên (bắt buộc)
    const volunteers = await VolunteerProfile.aggregate([
      {
        $geoNear: {
          near: {
            type: 'Point',
            coordinates: location.coordinates,
          },
          distanceField: 'distance',
          maxDistance: maxRadius * 1000, // chuyển km sang mét
          spherical: true,
          query: {
            status: 'APPROVED',
            ready: true,
            userId: { $nin: busyVolunteers },
          },
        },
      },
      {
        $lookup: {
          from: 'users',
          localField: 'userId',
          foreignField: '_id',
          as: 'user',
        },
      },
      {
        $unwind: '$user',
      },
      {
        $match: {
          'user.isActive': true,
          'user.roles': { $in: ['TNV_CN', 'TNV_TC'] },
        },
      },
      {
        $addFields: {
          // Convert distance from meters to kilometers
          distanceKm: {
            $divide: ['$distance', 1000],
          },
        },
      },
      {
        $sort: { distance: 1 },
      },
      {
        $limit: maxVolunteers,
      },
      {
        $project: {
          userId: 1,
          distance: { $divide: ['$distance', 1000] }, // distance in km
        },
      },
    ]);

    // Tạo queue cho từng TNV
    const queuePromises = volunteers.map((volunteer) =>
      SosResponderQueue.create({
        sosId: sosCase._id,
        volunteerId: volunteer.userId,
        distanceKm: volunteer.distance || volunteer.distanceKm || 0, // distance đã được convert sang km
        status: 'NOTIFIED',
      })
    );

    await Promise.all(queuePromises);

    // Gửi FCM notification cho tất cả TNV
    try {
      const notificationPromises = volunteers.map(async (volunteer) => {
        const distance = (volunteer.distance || volunteer.distanceKm || 0).toFixed(1);
        const title = '🚨 Có trường hợp khẩn cấp cần hỗ trợ';
        const body = `${sosCase.emergencyType} - Cách bạn ${distance}km`;

        return sendNotificationToUser(volunteer.userId, title, body, {
          type: 'SOS_CASE',
          caseId: sosCase._id.toString(),
          caseCode: sosCase.code,
          emergencyType: sosCase.emergencyType,
          distance: distance,
        });
      });

      await Promise.all(notificationPromises);
      console.log(`FCM notifications sent to ${volunteers.length} volunteers`);
    } catch (fcmError) {
      // Không throw error để không ảnh hưởng đến flow chính
      console.error('Error sending FCM notifications:', fcmError);
    }

    return volunteers;
  } catch (error) {
    console.error('Error finding volunteers:', error);
    throw error;
  }
};

// Tạo SOS case mới
const createSosCase = async (req, res, next) => {
  try {
    const {
      latitude,
      longitude,
      emergencyType,
      description,
      manualAddress,
      batteryLevel,
      isUrgent,
    } = req.body;

    const reporterId = req.user._id;

    // Validate input
    if (!latitude || !longitude) {
      throw new AppError('Latitude and longitude are required', 400);
    }

    if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
      throw new AppError('Invalid coordinates', 400);
    }

    if (!emergencyType || !description) {
      throw new AppError('Emergency type and description are required', 400);
    }

    // Tạo mã SOS unique
    const code = `SOS${Date.now()}${Math.random().toString(36).substr(2, 4).toUpperCase()}`;

    // Tạo case với vị trí ban đầu
    const sosCase = await SosCase.create({
      code,
      reporterId,
      location: {
        type: 'Point',
        coordinates: [parseFloat(longitude), parseFloat(latitude)],
      },
      emergencyType,
      description,
      manualAddress: manualAddress || null,
      batteryLevel: batteryLevel || null,
      isUrgent: isUrgent || false,
      status: 'SEARCHING',
      trackingStatus: 'ACTIVE',
    });

    // Tìm TNV gần nhất
    await findAndNotifyNearestVolunteers(sosCase);

    // Populate reporter info
    await sosCase.populate('reporterId', 'fullName phone avatar');

    res.status(201).json({
      success: true,
      data: {
        case: sosCase,
        reporterLocation: sosCase.location,
      },
    });
  } catch (error) {
    next(error);
  }
};

// TNV chấp nhận SOS case
const acceptSosCase = async (req, res, next) => {
  try {
    const { caseId } = req.params;
    const volunteerId = req.user._id;

    const sosCase = await findSosCaseByIdOrCode(caseId);
    if (!sosCase) {
      throw new AppError('SOS case not found', 404);
    }

    if (sosCase.status !== 'SEARCHING') {
      throw new AppError('SOS case is no longer available', 400);
    }

    // Kiểm tra TNV không đang trong case khác (sử dụng _id của case)
    const activeCase = await SosCase.findOne({
      _id: { $ne: sosCase._id },
      acceptedBy: volunteerId,
      status: { $in: ['ACCEPTED', 'IN_PROGRESS'] },
    });

    if (activeCase) {
      throw new AppError('You are already handling another SOS case', 400);
    }

    // Lấy thông tin TNV
    const volunteer = await User.findById(volunteerId);
    if (!volunteer) {
      throw new AppError('Volunteer not found', 404);
    }

    // Lấy vị trí từ VolunteerProfile hoặc request body
    const volunteerProfile = await VolunteerProfile.findOne({ userId: volunteerId });
    let responderLocation = null;

    if (volunteerProfile && volunteerProfile.homeBase && volunteerProfile.homeBase.location) {
      // Lấy từ homeBase (ưu tiên)
      responderLocation = volunteerProfile.homeBase.location;
    } else {
      // Fallback: Lấy từ request body nếu không có homeBase
      const body = req.body || {};
      const { latitude, longitude } = body;
      if (latitude && longitude) {
        // Validate coordinates
        if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
          throw new AppError('Invalid coordinates', 400);
        }
        responderLocation = {
          type: 'Point',
          coordinates: [parseFloat(longitude), parseFloat(latitude)],
        };
      } else {
        throw new AppError('Volunteer location not found. Please provide coordinates in request body (latitude, longitude) or set up homeBase in VolunteerProfile', 404);
      }
    }

    // Cập nhật case
    sosCase.status = 'ACCEPTED';
    sosCase.acceptedBy = volunteerId;
    sosCase.acceptedAt = new Date();
    sosCase.responderLocation = responderLocation;
    sosCase.responderInfo = {
      volunteerId,
      volunteerName: volunteer.fullName,
      volunteerPhone: volunteer.phone,
      acceptedAt: new Date(),
    };

    await sosCase.save();

    // Cập nhật queue (sử dụng _id của case)
    await SosResponderQueue.findOneAndUpdate(
      { sosId: sosCase._id, volunteerId },
      { status: 'ACCEPTED', respondedAt: new Date() }
    );

    // Từ chối các TNV khác
    await SosResponderQueue.updateMany(
      { sosId: sosCase._id, volunteerId: { $ne: volunteerId } },
      { status: 'DECLINED', respondedAt: new Date() }
    );

    // Populate thông tin
    await sosCase.populate('reporterId', 'fullName phone avatar');
    await sosCase.populate('acceptedBy', 'fullName phone avatar');

    // Tạo Google Maps directions URL
    const directionsUrl = getDirectionsUrl(sosCase.location, sosCase.responderLocation);

    res.json({
      success: true,
      data: {
        case: sosCase,
        reporterLocation: sosCase.location,
        responderLocation: sosCase.responderLocation,
        directionsUrl,
      },
    });
  } catch (error) {
    next(error);
  }
};

// Hủy SOS case
const cancelSosCase = async (req, res, next) => {
  try {
    const { caseId } = req.params;
    const { cancelReason } = req.body;
    const userId = req.user._id;
    const userRoles = req.user.roles || [];

    if (!cancelReason) {
      throw new AppError('Cancel reason is required', 400);
    }

    const sosCase = await findSosCaseByIdOrCode(caseId);
    if (!sosCase) {
      throw new AppError('SOS case not found', 404);
    }

    if (sosCase.status === 'CANCELLED') {
      throw new AppError('SOS case has been cancelled', 400);
    }

    // Xác định vai trò và quyền
    const isAdmin = userRoles.includes('ADMIN');
    const isReporter = sosCase.reporterId.toString() === userId.toString();
    const isVolunteer = sosCase.acceptedBy && sosCase.acceptedBy.toString() === userId.toString();

    let cancelledByRole = null;

    if (isAdmin) {
      cancelledByRole = 'ADMIN';
      // Admin có thể hủy bất kỳ lúc nào
    } else if (isReporter) {
      cancelledByRole = 'REPORTER';
      // Reporter chỉ hủy được khi SEARCHING hoặc ACCEPTED
      if (!['SEARCHING', 'ACCEPTED'].includes(sosCase.status)) {
        throw new AppError('Cannot cancel SOS case in current status', 400);
      }
    } else if (isVolunteer) {
      cancelledByRole = 'VOLUNTEER';
      // Volunteer chỉ hủy được case đã chấp nhận
      if (!['ACCEPTED', 'IN_PROGRESS'].includes(sosCase.status)) {
        throw new AppError('Cannot cancel SOS case in current status', 400);
      }
    } else {
      throw new AppError('Not authorized to cancel this SOS case', 403);
    }

    // Nếu volunteer hủy, reset về SEARCHING và tìm TNV mới
    if (cancelledByRole === 'VOLUNTEER') {
      // Reset về SEARCHING và tìm TNV mới
      sosCase.status = 'SEARCHING';
      sosCase.acceptedBy = null;
      sosCase.acceptedAt = null;
      sosCase.responderLocation = null;
      sosCase.responderInfo = {};
      await sosCase.save();

      // Tìm TNV mới
      await findAndNotifyNearestVolunteers(sosCase);
    } else {
      // Admin hoặc Reporter hủy - đặt status CANCELLED
      sosCase.status = 'CANCELLED';
      sosCase.cancelledBy = userId;
      sosCase.cancelledAt = new Date();
      sosCase.cancelReason = cancelReason;
      sosCase.cancelledByRole = cancelledByRole;
      await sosCase.save();

      // Cập nhật tất cả queue thành DECLINED
      await SosResponderQueue.updateMany(
        { sosId: sosCase._id },
        { status: 'DECLINED', respondedAt: new Date() }
      );
    }

    await sosCase.populate('reporterId', 'fullName phone avatar');
    if (sosCase.acceptedBy) {
      await sosCase.populate('acceptedBy', 'fullName phone avatar');
    }

    res.json({
      success: true,
      data: {
        case: sosCase,
        message: 'SOS case cancelled successfully',
      },
    });
  } catch (error) {
    next(error);
  }
};

// TNV từ chối case trong queue
const declineSosCase = async (req, res, next) => {
  try {
    const { caseId } = req.params;
    const { declineReason } = req.body;
    const volunteerId = req.user._id;

    if (!declineReason) {
      throw new AppError('Decline reason is required', 400);
    }

    const sosCase = await findSosCaseByIdOrCode(caseId);
    if (!sosCase) {
      throw new AppError('SOS case not found', 404);
    }

    if (sosCase.status === 'CANCELLED') {
      throw new AppError('SOS case has been cancelled', 400);
    }

    // Kiểm tra queue (sử dụng _id của case)
    const queueItem = await SosResponderQueue.findOne({
      sosId: sosCase._id,
      volunteerId,
    });

    if (!queueItem) {
      throw new AppError('You are not in the responder queue for this case', 404);
    }

    if (queueItem.status === 'DECLINED') {
      throw new AppError('You have already declined this case', 400);
    }

    if (queueItem.status === 'ACCEPTED') {
      throw new AppError('You have already accepted this case', 400);
    }

    // Cập nhật queue
    queueItem.status = 'DECLINED';
    queueItem.declineReason = declineReason;
    queueItem.declinedAt = new Date();
    queueItem.respondedAt = new Date();
    await queueItem.save();

    // Tìm TNV tiếp theo trong queue (sử dụng _id của case)
    const nextQueueItem = await SosResponderQueue.findOne({
      sosId: sosCase._id,
      status: 'NOTIFIED',
    }).sort({ distanceKm: 1 });

    if (!nextQueueItem && sosCase.status === 'SEARCHING') {
      // Không còn TNV, thông báo cho reporter
      // Có thể thêm logic thông báo ở đây
    }

    res.json({
      success: true,
      data: {
        message: 'Case declined successfully',
      },
    });
  } catch (error) {
    next(error);
  }
};

// Lấy chi tiết SOS case
const getSosCaseDetails = async (req, res, next) => {
  try {
    const { caseId } = req.params;

    const sosCase = await findSosCaseByIdOrCode(caseId);
    if (!sosCase) {
      throw new AppError('SOS case not found', 404);
    }

    await sosCase.populate('reporterId', 'fullName phone avatar');
    await sosCase.populate('acceptedBy', 'fullName phone avatar');
    const sosCaseObj = sosCase.toObject ? sosCase.toObject() : sosCase;

    let directionsUrl = null;
    if (sosCaseObj.responderLocation) {
      directionsUrl = getDirectionsUrl(sosCaseObj.location, sosCaseObj.responderLocation);
    }

    res.json({
      success: true,
      data: {
        case: sosCaseObj,
        reporterLocation: sosCaseObj.location,
        responderLocation: sosCaseObj.responderLocation || null,
        directionsUrl,
      },
    });
  } catch (error) {
    next(error);
  }
};

// Lấy danh sách SOS cases
const getSosCases = async (req, res, next) => {
  try {
    const {
      page = 1,
      limit = 10,
      status,
      emergencyType,
      reporterId,
      acceptedBy,
      sortBy = 'createdAt',
      sortOrder = 'desc',
    } = req.query;

    const query = {};

    if (status) {
      query.status = status;
    }

    if (emergencyType) {
      query.emergencyType = emergencyType;
    }

    if (reporterId) {
      query.reporterId = reporterId;
    }

    if (acceptedBy) {
      query.acceptedBy = acceptedBy;
    }

    const sort = {};
    sort[sortBy] = sortOrder === 'desc' ? -1 : 1;

    const cases = await SosCase.find(query)
      .populate('reporterId', 'fullName phone avatar')
      .populate('acceptedBy', 'fullName phone avatar')
      .sort(sort)
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .lean();

    const total = await SosCase.countDocuments(query);

    res.json({
      success: true,
      data: cases,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    next(error);
  }
};

// Lấy Google Maps directions URL
const getDirections = async (req, res, next) => {
  try {
    const { caseId } = req.params;

    const sosCase = await findSosCaseByIdOrCode(caseId);
    if (!sosCase) {
      throw new AppError('SOS case not found', 404);
    }

    const sosCaseObj = sosCase.toObject ? sosCase.toObject() : sosCase;

    if (!sosCaseObj.responderLocation) {
      throw new AppError('Responder location not available', 400);
    }

    const directionsUrl = getDirectionsUrl(sosCaseObj.location, sosCaseObj.responderLocation);

    const originLat = sosCaseObj.location.coordinates[1];
    const originLng = sosCaseObj.location.coordinates[0];
    const destLat = sosCaseObj.responderLocation.coordinates[1];
    const destLng = sosCaseObj.responderLocation.coordinates[0];

    res.json({
      success: true,
      data: {
        directionsUrl,
        origin: { lat: originLat, lng: originLng },
        destination: { lat: destLat, lng: destLng },
      },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  createSosCase,
  acceptSosCase,
  cancelSosCase,
  declineSosCase,
  getSosCaseDetails,
  getSosCases,
  getDirections,
  findAndNotifyNearestVolunteers,
  getDirectionsUrl,
};
