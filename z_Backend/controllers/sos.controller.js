const { SosCase, SosResponderQueue, VolunteerProfile, User, Notification } = require('../models');
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

    // [NEW] Tìm các TNV đang được thông báo cho một case khác (status SEARCHING + queue NOTIFIED)
    // Để tránh việc 1 người nhận 3 case cùng lúc
    const searchingCaseIds = await SosCase.find({ status: 'SEARCHING' }).distinct('_id');
    const notifiedVolunteers = await SosResponderQueue.find({
      sosId: { $in: searchingCaseIds },
      status: 'NOTIFIED',
    }).distinct('volunteerId');

    // Gộp danh sách loại trừ và convert sang ObjectId
    const excludedVolunteerIds = [...new Set([...busyVolunteers, ...notifiedVolunteers])]
      .map(id => new mongoose.Types.ObjectId(id));

    console.log(`🔍 Finding volunteers. Excluded: ${excludedVolunteerIds.length}, Radius: ${maxRadius}km`);

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
          key: 'homeBase.location', // Explicitly specify index key
          query: {
            status: 'APPROVED',
            ready: true,
            userId: { $nin: excludedVolunteerIds },
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
          ready: 1, // Include ready status for debugging
          status: 1 // Include profile status for debugging
        },
      },
    ]);

    console.log(`Found ${volunteers.length} volunteers. Details:`,
      volunteers.map(v => ({ id: v.userId, dist: v.distance, ready: v.ready }))
    );

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

    // Gửi FCM notification CHỈ cho TNV đầu tiên (gần nhất)
    try {
      if (volunteers.length > 0) {
        const firstVolunteer = volunteers[0];
        const distance = (firstVolunteer.distance || firstVolunteer.distanceKm || 0).toFixed(1);
        const title = '🚨 Có trường hợp khẩn cấp cần hỗ trợ';
        const body = `${sosCase.emergencyType} - Cách bạn ${distance}km`;

        // Tạo in-app notification
        const notificationData = {
          type: 'SOS_CASE',
          caseId: sosCase._id.toString(),
          caseCode: sosCase.code,
          emergencyType: sosCase.emergencyType,
          distance: distance,
        };

        // Lưu notification
        await Notification.create({
          userId: firstVolunteer.userId,
          type: 'SOS_CASE',
          title,
          body,
          data: notificationData,
          deliveredAt: new Date(),
        });

        // Gửi FCM
        await sendNotificationToUser(firstVolunteer.userId, title, body, notificationData);

        console.log(`✅ Notification sent to FIRST volunteer only (${distance}km away)`);
        console.log(`📋 ${volunteers.length - 1} other volunteers in queue as backup`);
      } else {
        console.log('⚠️ No volunteers found in range');
      }
    } catch (fcmError) {
      // Không throw error để không ảnh hưởng đến flow chính
      console.error('Error sending FCM notification to first volunteer:', fcmError);
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

    // Gửi thông báo cho reporter
    try {
      const reporterId = sosCase.reporterId._id || sosCase.reporterId;
      const title = '✅ Đã có TNV nhận hỗ trợ!';
      const body = `TNV ${volunteer.fullName} đang đến vị trí của bạn.`;
      const notificationData = {
        type: 'SOS_ACCEPTED',
        caseId: sosCase._id.toString(),
        volunteerId: volunteerId.toString(),
        volunteerName: volunteer.fullName,
        volunteerPhone: volunteer.phone,
      };

      // Lưu in-app notification
      await Notification.create({
        userId: reporterId,
        type: 'SOS_ACCEPTED',
        title,
        body,
        data: notificationData,
        deliveredAt: new Date(),
      });

      // Gửi FCM
      sendNotificationToUser(reporterId, title, body, notificationData).catch(err =>
        console.error('Error sending notification to reporter:', err)
      );
    } catch (notifyError) {
      console.error('Error notifying reporter:', notifyError);
    }

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

    // Populate reporterId để có thể compare
    if (!sosCase.populated('reporterId')) {
      await sosCase.populate('reporterId', '_id');
    }

    // Xác định vai trò và quyền
    const isAdmin = userRoles.includes('ADMIN');
    const reporterIdStr = sosCase.reporterId?._id ? sosCase.reporterId._id.toString() : sosCase.reporterId.toString();
    const isReporter = reporterIdStr === userId.toString();
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

      // Gửi thông báo cho tất cả TNV trong queue khi REPORTER/ADMIN hủy
      try {
        const queueItems = await SosResponderQueue.find({
          sosId: sosCase._id,
          status: 'DECLINED',
        }).distinct('volunteerId');

        console.log(`📢 Notifying ${queueItems.length} volunteers about SOS cancellation`);

        const notificationPromises = queueItems.map(async (volunteerId) => {
          try {
            const title = '❌ Yêu cầu SOS đã bị hủy';
            const body = `Người dùng đã hủy yêu cầu ${sosCase.emergencyType}`;
            const notificationData = {
              type: 'SOS_CANCELLED',
              caseId: sosCase._id.toString(),
              caseCode: sosCase.code,
              emergencyType: sosCase.emergencyType,
              cancelReason: cancelReason,
              cancelledByRole: cancelledByRole,
            };

            // Lưu in-app notification
            const notificationPromise = Notification.create({
              userId: volunteerId,
              type: 'SOS_CANCELLED',
              title,
              body,
              data: notificationData,
              deliveredAt: new Date(),
            });

            // Gửi FCM
            const fcmPromise = sendNotificationToUser(volunteerId, title, body, notificationData);

            return Promise.all([notificationPromise, fcmPromise]);
          } catch (error) {
            console.error(`Error notifying volunteer ${volunteerId}:`, error);
            return null;
          }
        });

        await Promise.all(notificationPromises);
        console.log('✅ Cancellation notifications sent to all volunteers');

        // NOTIFY NEXT SOS: Find and notify each volunteer of their next oldest pending SOS
        console.log(`🔍 Finding next pending SOS for ${queueItems.length} volunteers...`);

        const nextSosPromises = queueItems.map(async (volunteerId) => {
          try {
            // Get volunteer profile for homeBase location
            const volunteerProfile = await VolunteerProfile.findOne({
              userId: volunteerId,
              status: 'APPROVED',
              ready: true
            });

            if (!volunteerProfile) {
              console.log(`ℹ️ Volunteer ${volunteerId} not ready or not approved`);
              return null;
            }

            // Find oldest pending SOS case within 50km (excluding the canceled one)
            const nextPendingCases = await SosCase.aggregate([
              {
                $match: {
                  status: 'SEARCHING',
                  _id: { $ne: sosCase._id }
                }
              },
              {
                $geoNear: {
                  near: volunteerProfile.homeBase.location,
                  distanceField: 'distance',
                  maxDistance: 50000, // 50km in meters
                  spherical: true
                }
              },
              {
                $sort: { createdAt: 1 } // Oldest first
              },
              {
                $limit: 1
              }
            ]);

            if (nextPendingCases.length > 0) {
              const nextCase = nextPendingCases[0];

              // Check if volunteer already in queue for this case
              const existingQueue = await SosResponderQueue.findOne({
                sosId: nextCase._id,
                volunteerId
              });

              if (!existingQueue) {
                // Add to queue
                await SosResponderQueue.create({
                  sosId: nextCase._id,
                  volunteerId,
                  distanceKm: nextCase.distance / 1000,
                  status: 'NOTIFIED'
                });

                // Send notification
                const distance = (nextCase.distance / 1000).toFixed(1);
                const nextTitle = '🚨 Có trường hợp khẩn cấp cần hỗ trợ';
                const nextBody = `${nextCase.emergencyType} - Cách bạn ${distance}km`;

                const nextNotificationData = {
                  type: 'SOS_CASE',
                  caseId: nextCase._id.toString(),
                  caseCode: nextCase.code,
                  emergencyType: nextCase.emergencyType,
                  distance: distance
                };

                // Save in-app notification
                await Notification.create({
                  userId: volunteerId,
                  type: 'SOS_CASE',
                  title: nextTitle,
                  body: nextBody,
                  data: nextNotificationData,
                  deliveredAt: new Date()
                });

                // Send FCM
                await sendNotificationToUser(volunteerId, nextTitle, nextBody, nextNotificationData);

                console.log(`✅ Notified volunteer of next oldest SOS (${distance}km, created ${nextCase.createdAt})`);
                return nextCase._id;
              } else {
                console.log(`ℹ️ Volunteer already in queue for next pending SOS`);
                return null;
              }
            } else {
              console.log(`ℹ️ No other pending SOS found for volunteer ${volunteerId}`);
              return null;
            }
          } catch (error) {
            console.error(`Error finding next SOS for volunteer ${volunteerId}:`, error);
            return null;
          }
        });

        const nextSosResults = await Promise.all(nextSosPromises);
        const notifiedCount = nextSosResults.filter(result => result !== null).length;
        console.log(`📢 Notified ${notifiedCount} volunteers of their next oldest pending SOS`);

      } catch (notifyError) {
        // Không throw error để không ảnh hưởng đến flow chính
        console.error('Error sending cancellation notifications:', notifyError);
      }
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
    // Loop để tìm người tiếp theo thỏa mãn điều kiện (ready + active)
    let nextVolunteerFound = false;
    let currentQueueItem = null;

    while (!nextVolunteerFound) {
      currentQueueItem = await SosResponderQueue.findOne({
        sosId: sosCase._id,
        status: 'NOTIFIED',
      }).sort({ distanceKm: 1 });

      if (!currentQueueItem) break; // Hết queue

      // Check status của volunteer này hiện tại
      const volunteerProfile = await VolunteerProfile.findOne({ userId: currentQueueItem.volunteerId });
      const user = await User.findById(currentQueueItem.volunteerId);

      // Nếu user active và volunteer ready -> OK
      if (user && user.isActive && volunteerProfile && volunteerProfile.status === 'APPROVED' && volunteerProfile.ready) {
        nextVolunteerFound = true;
      } else {
        // Nếu không thỏa mãn, đánh dấu là SKIPPED hoặc DECLINED (system declined)
        currentQueueItem.status = 'DECLINED';
        currentQueueItem.declineReason = 'System: Volunteer not ready or inactive';
        currentQueueItem.respondedAt = new Date();
        await currentQueueItem.save();
        // Loop tiếp tục tìm người sau
      }
    }

    if (nextVolunteerFound && currentQueueItem && sosCase.status === 'SEARCHING') {
      // Gửi notification cho TNV tiếp theo
      try {
        const distance = currentQueueItem.distanceKm.toFixed(1);
        const title = '🚨 Có trường hợp khẩn cấp cần hỗ trợ';
        const body = `${sosCase.emergencyType} - Cách bạn ${distance}km`;
        const notificationData = {
          type: 'SOS_CASE',
          caseId: sosCase._id.toString(),
          caseCode: sosCase.code,
          emergencyType: sosCase.emergencyType,
          distance: distance,
        };

        // Lưu in-app notification
        await Notification.create({
          userId: currentQueueItem.volunteerId,
          type: 'SOS_CASE',
          title,
          body,
          data: notificationData,
          deliveredAt: new Date(),
        });

        // Gửi FCM
        await sendNotificationToUser(currentQueueItem.volunteerId, title, body, notificationData);

        console.log(`✅ Notified NEXT volunteer after decline (${distance}km away)`);
      } catch (notifyError) {
        console.error('Error notifying next volunteer:', notifyError);
      }
    } else if (!nextVolunteerFound && sosCase.status === 'SEARCHING') {
      console.log('⚠️ No more volunteers in queue - all declined or skipped');
      // Có thể thông báo cho reporter: "Không tìm thấy TNV"
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
    console.log(`[getSosCaseDetails] Request for caseId: ${caseId}`);

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

// Hoàn thành SOS case (TNV)
const completeSosCase = async (req, res, next) => {
  try {
    const { caseId } = req.params;
    const volunteerId = req.user._id;

    const sosCase = await findSosCaseByIdOrCode(caseId);
    if (!sosCase) {
      throw new AppError('SOS case not found', 404);
    }

    // Verify: chỉ volunteer đã accept mới được complete
    if (!sosCase.acceptedBy || sosCase.acceptedBy.toString() !== volunteerId.toString()) {
      throw new AppError('Only the volunteer who accepted this case can complete it', 403);
    }

    // Verify: case phải ở trạng thái ACCEPTED hoặc IN_PROGRESS
    if (!['ACCEPTED', 'IN_PROGRESS'].includes(sosCase.status)) {
      throw new AppError('Cannot complete case in current status', 400);
    }

    // Update case status to RESOLVED
    sosCase.status = 'RESOLVED';
    sosCase.resolvedAt = new Date();
    await sosCase.save();

    // Update queue status
    await SosResponderQueue.findOneAndUpdate(
      { sosId: sosCase._id, volunteerId },
      { status: 'COMPLETED', respondedAt: new Date() }
    );

    // Get volunteer info
    const volunteer = await User.findById(volunteerId);

    // Populate thông tin
    await sosCase.populate('reporterId', 'fullName phone avatar');
    await sosCase.populate('acceptedBy', 'fullName phone avatar');

    // [AUTO-CATCH] Tìm và thông báo ca SOS tiếp theo cho TNV vừa hoàn thành
    try {
      console.log(`[Auto-Catch] Volunteer ${volunteerId} completed case. Searching for next pending SOS...`);

      // Lấy thông tin volunteer profile để có vị trí homeBase
      const volunteerProfile = await VolunteerProfile.findOne({
        userId: volunteerId,
        status: 'APPROVED',
        ready: true
      });

      if (volunteerProfile && volunteerProfile.homeBase && volunteerProfile.homeBase.location) {
        // Tìm pending SOS cases trong bán kính 50km
        const nextPendingCases = await SosCase.aggregate([
          {
            $geoNear: {
              near: volunteerProfile.homeBase.location,
              distanceField: 'distance',
              maxDistance: 50000, // 50km
              spherical: true,
              key: 'location',
              query: { status: 'SEARCHING' }
            }
          },
          { $sort: { createdAt: 1 } }, // Ưu tiên ca cũ nhất
          { $limit: 1 } // Chỉ lấy 1 ca để không spam
        ]);

        if (nextPendingCases.length > 0) {
          const nextCase = nextPendingCases[0];
          console.log(`[Auto-Catch] Found next case: ${nextCase._id}`);

          // Kiểm tra xem đã có trong queue chưa
          const existingQueue = await SosResponderQueue.findOne({
            sosId: nextCase._id,
            volunteerId
          });

          if (!existingQueue) {
            console.log(`[Auto-Catch] Creating queue item for volunteer ${volunteerId}`);
            // Thêm vào queue
            await SosResponderQueue.create({
              sosId: nextCase._id,
              volunteerId,
              distanceKm: nextCase.distance / 1000,
              status: 'NOTIFIED'
            });

            // Gửi thông báo
            const distance = (nextCase.distance / 1000).toFixed(1);
            const nextTitle = '🚨 Có trường hợp khẩn cấp cần hỗ trợ';
            const nextBody = `${nextCase.emergencyType} - Cách bạn ${distance}km`;

            const nextNotificationData = {
              type: 'SOS_CASE',
              caseId: nextCase._id.toString(),
              caseCode: nextCase.code,
              emergencyType: nextCase.emergencyType,
              distance: distance
            };

            console.log(`[Auto-Catch] Creating notification for volunteer ${volunteerId}`);
            // Lưu notification
            await Notification.create({
              userId: volunteerId,
              type: 'SOS_CASE',
              title: nextTitle,
              body: nextBody,
              data: nextNotificationData,
              deliveredAt: new Date()
            });

            console.log(`[Auto-Catch] Sending FCM to volunteer ${volunteerId}`);
            // Gửi FCM
            await sendNotificationToUser(volunteerId, nextTitle, nextBody, nextNotificationData);

            console.log(`✅ [Auto-Catch] Notified volunteer of next SOS ${nextCase._id} (${distance}km)`);
          } else {
            console.log(`[Auto-Catch] Volunteer ${volunteerId} already in queue for case ${nextCase._id}`);
          }
        } else {
          console.log(`[Auto-Catch] No pending cases found nearby.`);
        }
      }
    } catch (autoCatchError) {
      console.error('[Auto-Catch] Error:', autoCatchError);
      // Không throw error để không ảnh hưởng flow chính
    }

    // Send notification to reporter
    try {
      const reporterId = sosCase.reporterId._id || sosCase.reporterId;
      const title = '✅ Ứng cứu đã hoàn thành';
      const body = `TNV ${volunteer?.fullName || 'Tình nguyện viên'} đã hoàn thành ứng cứu. Cảm ơn bạn đã sử dụng dịch vụ!`;
      const notificationData = {
        type: 'SOS_COMPLETED',
        caseId: sosCase._id.toString(),
        volunteerId: volunteerId.toString(),
        completedAt: sosCase.resolvedAt.toISOString(),
      };

      // Lưu in-app notification
      await Notification.create({
        userId: reporterId,
        type: 'SOS_COMPLETED',
        title,
        body,
        data: notificationData,
        deliveredAt: new Date(),
      });

      // Gửi FCM
      sendNotificationToUser(reporterId, title, body, notificationData).catch(err =>
        console.error('Error sending completion notification to reporter:', err)
      );
    } catch (notifyError) {
      console.error('Error notifying reporter about completion:', notifyError);
    }

    res.json({
      success: true,
      data: {
        case: sosCase,
        message: 'SOS case completed successfully',
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

// Lấy SOS case đang hoạt động của user (nếu có)
const getActiveSosCase = async (req, res, next) => {
  try {
    const userId = req.user._id;

    // Tìm case mới nhất đang active mà user là reporter HOẶC volunteer
    const activeCase = await SosCase.findOne({
      $or: [
        { reporterId: userId },
        { acceptedBy: userId }
      ],
      status: { $in: ['SEARCHING', 'ACCEPTED', 'IN_PROGRESS'] }
    })
      .populate('reporterId', 'fullName phone avatar')
      .populate('acceptedBy', 'fullName phone avatar')
      .sort({ createdAt: -1 });

    if (!activeCase) {
      return res.json({
        success: true,
        data: null
      });
    }

    // Xác định vai trò của user trong case này
    let role = 'UNKNOWN';
    if (activeCase.reporterId._id.toString() === userId.toString()) {
      role = 'REPORTER';
    } else if (activeCase.acceptedBy && activeCase.acceptedBy._id.toString() === userId.toString()) {
      role = 'VOLUNTEER';
    }

    res.json({
      success: true,
      data: {
        ...activeCase.toObject(),
        userRole: role // Trả về role để frontend dễ xử lý
      }
    });
  } catch (error) {
    next(error);
  }
};

// TNV đánh dấu đã xem case (soft dismiss - không từ chối)
const markSosCaseAsSeen = async (req, res, next) => {
  try {
    const { caseId } = req.params;
    const volunteerId = req.user._id;

    const sosCase = await findSosCaseByIdOrCode(caseId);
    if (!sosCase) {
      throw new AppError('SOS case not found', 404);
    }

    if (sosCase.status === 'CANCELLED') {
      throw new AppError('SOS case has been cancelled', 400);
    }

    // Kiểm tra queue
    const queueItem = await SosResponderQueue.findOne({
      sosId: sosCase._id,
      volunteerId,
    });

    if (!queueItem) {
      throw new AppError('You are not in the responder queue for this case', 404);
    }

    if (queueItem.status === 'ACCEPTED') {
      throw new AppError('You have already accepted this case', 400);
    }

    // Cập nhật queue thành SEEN (không phải DECLINED)
    queueItem.status = 'SEEN';
    queueItem.seenAt = new Date();
    await queueItem.save();

    console.log(`✅ Volunteer ${volunteerId} marked case ${caseId} as SEEN (soft dismiss)`);

    res.json({
      success: true,
      data: {
        message: 'Marked as seen',
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
  completeSosCase,
  getSosCaseDetails,
  getSosCases,
  getDirections,
  findAndNotifyNearestVolunteers,
  getDirectionsUrl,
  getActiveSosCase,
  markSosCaseAsSeen,
};

