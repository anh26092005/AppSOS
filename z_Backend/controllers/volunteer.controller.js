const { VolunteerProfile, User, SosCase, SosResponderQueue, Notification } = require('../models');
const AppError = require('../utils/appError');
const { sendNotificationToUser } = require('../services/fcm.service');

// Tạo volunteer profile mới
const createVolunteerProfile = async (req, res, next) => {
  try {
    const {
      userId,
      type,
      skills,
      homeBase,
      organization,
      idCardFront,
      idCardBack,
    } = req.body;

    // Validate required fields
    if (!userId) {
      throw new AppError('User ID is required', 400);
    }

    if (!type || !['CN', 'TC'].includes(type)) {
      throw new AppError('Type is required and must be CN or TC', 400);
    }

    if (!homeBase || !homeBase.location || !homeBase.location.coordinates) {
      throw new AppError('Home base location is required', 400);
    }

    // Validate coordinates
    const [longitude, latitude] = homeBase.location.coordinates;
    if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
      throw new AppError('Invalid coordinates', 400);
    }

    // Kiểm tra user tồn tại
    const user = await User.findById(userId);
    if (!user) {
      throw new AppError('User not found', 404);
    }

    // Kiểm tra đã có volunteer profile chưa
    const existingProfile = await VolunteerProfile.findOne({ userId });
    if (existingProfile) {
      throw new AppError('Volunteer profile already exists for this user', 400);
    }

    // Tạo volunteer profile
    const volunteerProfile = await VolunteerProfile.create({
      userId,
      type,
      skills: skills || [],
      homeBase: {
        location: {
          type: 'Point',
          coordinates: [parseFloat(longitude), parseFloat(latitude)],
        },
        radiusKm: homeBase.radiusKm || 5,
      },
      organization: organization || null,
      idCardFront: idCardFront || null,
      idCardBack: idCardBack || null,
      status: 'PENDING',
      ready: false,
    });

    // Populate user info
    await volunteerProfile.populate('userId', 'fullName phone email avatar roles isActive');

    res.status(201).json({
      success: true,
      data: volunteerProfile,
      message: 'Volunteer profile created successfully',
    });
  } catch (error) {
    next(error);
  }
};

// Lấy danh sách volunteers
const getVolunteers = async (req, res, next) => {
  try {
    const {
      page = 1,
      limit = 10,
      status,
      type,
      sortBy = 'createdAt',
      sortOrder = 'desc',
    } = req.query;

    const query = {};

    // Filter theo status
    if (status) {
      query.status = status;
    }

    // Filter theo type
    if (type) {
      query.type = type;
    }

    const sort = {};
    sort[sortBy] = sortOrder === 'desc' ? -1 : 1;

    const volunteers = await VolunteerProfile.find(query)
      .populate('userId', 'fullName phone email avatar roles isActive')
      .sort(sort)
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .lean();

    const total = await VolunteerProfile.countDocuments(query);

    res.json({
      success: true,
      data: volunteers,
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

// Lấy chi tiết volunteer
const getVolunteerById = async (req, res, next) => {
  try {
    const { id } = req.params;

    const volunteer = await VolunteerProfile.findById(id)
      .populate('userId', 'fullName phone email avatar roles isActive')
      .lean();

    if (!volunteer) {
      throw new AppError('Volunteer not found', 404);
    }

    res.json({
      success: true,
      data: volunteer,
    });
  } catch (error) {
    next(error);
  }
};

// Lấy chi tiết volunteer theo userId (public/authenticated user)
const getVolunteerByUserId = async (req, res, next) => {
  try {
    const { userId } = req.params;

    const volunteer = await VolunteerProfile.findOne({ userId })
      .populate('userId', 'fullName phone email avatar roles isActive')
      .lean();

    if (!volunteer) {
      // Không tìm thấy profile tình nguyện viên, trả về null hoặc lỗi 404 tùy logic frontend
      // Ở đây trả về 404 để frontend biết
      throw new AppError('Volunteer profile not found', 404);
    }

    res.json({
      success: true,
      data: volunteer,
    });
  } catch (error) {
    next(error);
  }
};

// Phê duyệt volunteer
const approveVolunteer = async (req, res, next) => {
  try {
    const { id } = req.params;

    const volunteer = await VolunteerProfile.findById(id);
    if (!volunteer) {
      throw new AppError('Volunteer not found', 404);
    }

    if (volunteer.status === 'APPROVED') {
      throw new AppError('Volunteer is already approved', 400);
    }

    // Cập nhật volunteer profile
    volunteer.status = 'APPROVED';
    volunteer.approvedAt = new Date();
    volunteer.ready = true;
    await volunteer.save();

    // Cập nhật User roles
    const user = await User.findById(volunteer.userId);
    if (user) {
      // Thêm role TNV_CN hoặc TNV_TC dựa trên volunteer type
      const volunteerRole = volunteer.type === 'CN' ? 'TNV_CN' : 'TNV_TC';
      if (!user.roles.includes(volunteerRole)) {
        user.roles.push(volunteerRole);
        await user.save();
      }
    }

    const volunteerObj = await VolunteerProfile.findById(id)
      .populate('userId', 'fullName phone email avatar roles isActive')
      .lean();

    res.json({
      success: true,
      data: volunteerObj,
      message: 'Volunteer approved successfully',
    });
  } catch (error) {
    next(error);
  }
};

// Từ chối volunteer
const rejectVolunteer = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { reviewNotes } = req.body;

    if (!reviewNotes) {
      throw new AppError('Review notes are required', 400);
    }

    const volunteer = await VolunteerProfile.findById(id);
    if (!volunteer) {
      throw new AppError('Volunteer not found', 404);
    }

    if (volunteer.status === 'REJECTED') {
      throw new AppError('Volunteer is already rejected', 400);
    }

    // Cập nhật volunteer profile
    volunteer.status = 'REJECTED';
    volunteer.reviewNotes = reviewNotes;
    volunteer.ready = false;
    await volunteer.save();

    const volunteerObj = await VolunteerProfile.findById(id)
      .populate('userId', 'fullName phone email avatar roles isActive')
      .lean();

    res.json({
      success: true,
      data: volunteerObj,
      message: 'Volunteer rejected successfully',
    });
  } catch (error) {
    next(error);
  }
};

// Cập nhật volunteer profile
const updateVolunteer = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { ready, skills, reviewNotes } = req.body;

    const volunteer = await VolunteerProfile.findById(id);
    if (!volunteer) {
      throw new AppError('Volunteer not found', 404);
    }

    // Cập nhật ready status
    if (ready !== undefined) {
      volunteer.ready = ready;
    }

    // Cập nhật skills
    if (skills && Array.isArray(skills)) {
      volunteer.skills = skills;
    }

    // Cập nhật review notes
    if (reviewNotes !== undefined) {
      volunteer.reviewNotes = reviewNotes;
    }

    await volunteer.save();

    const volunteerObj = await VolunteerProfile.findById(id)
      .populate('userId', 'fullName phone email avatar roles isActive')
      .lean();

    res.json({
      success: true,
      data: volunteerObj,
    });
  } catch (error) {
    next(error);
  }
};

// TNV toggle ready status (tự toggle, không cần admin)
const toggleVolunteerReady = async (req, res, next) => {
  try {
    const userId = req.user._id;

    // Verify user is a volunteer
    const userRoles = req.user.roles || [];
    const isTNV = userRoles.includes('TNV_CN') || userRoles.includes('TNV_TC');

    if (!isTNV) {
      throw new AppError('Only volunteers can toggle ready status', 403);
    }

    const volunteer = await VolunteerProfile.findOne({ userId });
    if (!volunteer) {
      throw new AppError('Volunteer profile not found', 404);
    }

    // Store previous ready status
    const wasReady = volunteer.ready;

    // Toggle ready status
    volunteer.ready = !volunteer.ready;
    await volunteer.save();

    // If toggled from OFF to ON, notify of oldest pending SOS
    if (!wasReady && volunteer.ready === true) {
      try {
        // Find oldest pending SOS case within 50km
        const oldestPendingCases = await SosCase.aggregate([
          {
            $match: { status: 'SEARCHING' }
          },
          {
            $geoNear: {
              near: volunteer.homeBase.location,
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

        if (oldestPendingCases.length > 0) {
          const oldestCase = oldestPendingCases[0];

          // Check if volunteer already in queue for this case
          const existingQueue = await SosResponderQueue.findOne({
            sosId: oldestCase._id,
            volunteerId: userId
          });

          if (!existingQueue) {
            // Add to queue
            await SosResponderQueue.create({
              sosId: oldestCase._id,
              volunteerId: userId,
              distanceKm: oldestCase.distance / 1000,
              status: 'NOTIFIED'
            });

            // Send notification
            const distance = (oldestCase.distance / 1000).toFixed(1);
            const title = '🚨 Có trường hợp khẩn cấp cần hỗ trợ';
            const body = `${oldestCase.emergencyType} - Cách bạn ${distance}km`;

            const notificationData = {
              type: 'SOS_CASE',
              caseId: oldestCase._id.toString(),
              caseCode: oldestCase.code,
              emergencyType: oldestCase.emergencyType,
              distance: distance
            };

            // Save in-app notification
            await Notification.create({
              userId: userId,
              type: 'SOS_CASE',
              title,
              body,
              data: notificationData,
              deliveredAt: new Date()
            });

            // Send FCM
            await sendNotificationToUser(userId, title, body, notificationData);

            console.log(`✅ Notified volunteer of oldest pending SOS (${distance}km, created ${oldestCase.createdAt})`);
          } else {
            console.log('ℹ️ Volunteer already in queue for oldest pending SOS');
          }
        } else {
          console.log('ℹ️ No pending SOS cases found in range');
        }
      } catch (notifyError) {
        // Log error but don't fail the toggle operation
        console.error('Error notifying volunteer of pending SOS:', notifyError);
      }
    }

    const volunteerObj = await VolunteerProfile.findById(volunteer._id)
      .populate('userId', 'fullName phone email avatar roles isActive')
      .lean();

    res.json({
      success: true,
      data: volunteerObj,
      message: `Ready status changed to ${volunteer.ready ? 'ACTIVE' : 'INACTIVE'}`,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  createVolunteerProfile,
  getVolunteers,
  getVolunteerById,
  getVolunteerByUserId,
  approveVolunteer,
  rejectVolunteer,
  updateVolunteer,
  toggleVolunteerReady,
};

