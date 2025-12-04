const { SosCase, SosResponderQueue, VolunteerProfile, User, Notification } = require('../models');
const { sendNotificationToUser } = require('../services/fcm.service');

let isProcessing = false;
let intervalId = null;

/**
 * Cleanup Queue Job
 * Chạy mỗi 10 giây để:
 * 1. Tìm TNV timeout (không phản hồi sau 30s)
 * 2. Expire queue items
 * 3. Notify TNV tiếp theo HOẶC auto-cancel case
 */
const cleanupQueue = async () => {
    if (isProcessing) {
        console.log('⏭️  Previous cleanup still running, skipping...');
        return;
    }

    isProcessing = true;

    try {
        const now = new Date();
        const thirtySecondsAgo = new Date(now.getTime() - 30000); // 30 seconds

        // Tìm queue items đã timeout (status NOTIFIED, notifiedAt > 30s ago)
        // Chỉ xử lý cases gần đây (trong 10 phút) để tối ưu performance
        const expiredItems = await SosResponderQueue.find({
            status: 'NOTIFIED',
            notifiedAt: { $lte: thirtySecondsAgo },
            updatedAt: { $gte: new Date(now.getTime() - 10 * 60000) }, // Within last 10 mins
        })
            .limit(100)
            .populate('sosId')
            .lean();

        if (expiredItems.length === 0) {
            // console.log('✅  No expired queue items');
            return;
        }

        console.log(`🔍  Found ${expiredItems.length} expired queue items`);

        // Group by sosId để xử lý từng case
        const caseGroups = {};
        for (const item of expiredItems) {
            // Check if sosId exists (populated)
            // Check if sosId exists (populated)
            if (!item.sosId) {
                console.log(`⚠️  Deleting orphan queue item ${item._id} (missing sosId)`);
                try {
                    await SosResponderQueue.findByIdAndDelete(item._id);
                    console.log(`✅  Deleted orphan item ${item._id}`);
                } catch (err) {
                    console.error(`❌  Failed to delete orphan item ${item._id}:`, err);
                }
                continue;
            }

            const caseId = item.sosId._id.toString();
            if (!caseGroups[caseId]) {
                caseGroups[caseId] = [];
            }
            caseGroups[caseId].push(item);
        }

        // Xử lý từng case
        for (const [caseId, items] of Object.entries(caseGroups)) {
            await processCaseTimeout(items[0].sosId, items);
        }

        console.log(`✅  Processed ${expiredItems.length} expired items across ${Object.keys(caseGroups).length} cases`);
    } catch (error) {
        console.error('❌  Error in cleanupQueue:', error);
    } finally {
        isProcessing = false;
    }
};

/**
 * Xử lý timeout cho 1 case cụ thể
 */
const processCaseTimeout = async (sosCase, expiredItems) => {
    try {
        // Verify case vẫn ở trạng thái SEARCHING
        if (sosCase.status !== 'SEARCHING') {
            // Case đã được accept hoặc cancel bởi user/volunteer
            console.log(`⏭️  Case ${sosCase.code} is ${sosCase.status}, skipping timeout`);
            return;
        }

        // Mark items as EXPIRED
        const expiredVolunteerIds = expiredItems.map((item) => item.volunteerId);
        await SosResponderQueue.updateMany(
            {
                _id: { $in: expiredItems.map((item) => item._id) },
            },
            {
                $set: {
                    status: 'EXPIRED',
                    respondedAt: new Date(),
                },
            }
        );

        console.log(`⏰  Expired ${expiredItems.length} items for case ${sosCase.code}`);

        // Tìm TNV tiếp theo trong queue (chưa expired, status NOTIFIED)
        const nextVolunteer = await findNextValidVolunteer(sosCase._id);

        if (nextVolunteer) {
            // Có TNV tiếp theo → Gửi notification
            await notifyVolunteer(sosCase, nextVolunteer);
            console.log(`📢  Notified next volunteer for case ${sosCase.code}`);
        } else {
            // Hết TNV → Auto-cancel case
            await autoCancelCase(sosCase);
            console.log(`❌  Auto-cancelled case ${sosCase.code} - no volunteers available`);
        }
    } catch (error) {
        console.error(`Error processing timeout for case ${sosCase.code}:`, error);
    }
};

/**
 * Tìm TNV tiếp theo hợp lệ (ready + active)
 */
const findNextValidVolunteer = async (sosId) => {
    // Loop để tìm người tiếp theo thỏa mãn điều kiện
    let found = false;
    let currentQueue = null;

    while (!found) {
        currentQueue = await SosResponderQueue.findOne({
            sosId,
            status: 'NOTIFIED',
        }).sort({ distanceKm: 1 });

        if (!currentQueue) break; // Hết queue

        // Check status của volunteer
        const volunteerProfile = await VolunteerProfile.findOne({ userId: currentQueue.volunteerId });
        const user = await User.findById(currentQueue.volunteerId);

        if (
            user &&
            user.isActive &&
            volunteerProfile &&
            volunteerProfile.status === 'APPROVED' &&
            volunteerProfile.ready
        ) {
            found = true;
        } else {
            // System decline vì volunteer không ready
            await SosResponderQueue.updateOne(
                { _id: currentQueue._id },
                {
                    $set: {
                        status: 'DECLINED',
                        declineReason: 'System: Volunteer not ready or inactive',
                        respondedAt: new Date(),
                    },
                }
            );
        }
    }

    return found ? currentQueue : null;
};

/**
 * Gửi notification cho TNV
 */
const notifyVolunteer = async (sosCase, queueItem) => {
    try {
        const distance = queueItem.distanceKm.toFixed(1);
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
            userId: queueItem.volunteerId,
            type: 'SOS_CASE',
            title,
            body,
            data: notificationData,
            deliveredAt: new Date(),
        });

        // Gửi FCM
        await sendNotificationToUser(queueItem.volunteerId, title, body, notificationData);
    } catch (error) {
        console.error('Error notifying volunteer:', error);
    }
};

/**
 * Auto-cancel case khi hết TNV
 */
const autoCancelCase = async (sosCase) => {
    try {
        // Update case
        sosCase.status = 'CANCELLED';
        sosCase.cancelReason = 'Không tìm thấy tình nguyện viên trong khu vực';
        sosCase.cancelledByRole = 'SYSTEM';
        sosCase.cancelledAt = new Date();
        sosCase.meta.autoCancelledDueToTimeout = true;
        await sosCase.save();

        // Decline tất cả queue items còn lại
        await SosResponderQueue.updateMany(
            { sosId: sosCase._id, status: 'NOTIFIED' },
            {
                $set: {
                    status: 'DECLINED',
                    declineReason: 'System: Case auto-cancelled',
                    respondedAt: new Date(),
                },
            }
        );

        // Gửi notification cho user
        const title = '❌ Không tìm thấy tình nguyện viên';
        const body = 'Rất tiếc, không có tình nguyện viên nào trong khu vực của bạn lúc này. Vui lòng liên hệ số khẩn cấp.';

        const notificationData = {
            type: 'SOS_AUTO_CANCELLED',
            caseId: sosCase._id.toString(),
            caseCode: sosCase.code,
            cancelReason: 'NO_VOLUNTEERS_AVAILABLE',
            emergencyType: sosCase.emergencyType, // Để frontend biết highlight số nào
        };

        // Lưu notification
        await Notification.create({
            userId: sosCase.reporterId,
            type: 'SOS_AUTO_CANCELLED',
            title,
            body,
            data: notificationData,
            deliveredAt: new Date(),
        });

        // Gửi FCM
        await sendNotificationToUser(sosCase.reporterId, title, body, notificationData);
    } catch (error) {
        console.error('Error in autoCancelCase:', error);
    }
};

/**
 * Start cron job
 */
const start = () => {
    if (intervalId) {
        console.log('⚠️  Cleanup queue job already running');
        return;
    }

    console.log('🚀  Starting cleanup queue job (every 10 seconds)...');
    intervalId = setInterval(cleanupQueue, 10000); // 10 seconds

    // Run immediately once
    cleanupQueue();
};

/**
 * Stop cron job
 */
const stop = () => {
    if (intervalId) {
        clearInterval(intervalId);
        intervalId = null;
        console.log('🛑  Stopped cleanup queue job');
    }
};

module.exports = {
    start,
    stop,
    cleanupQueue, // Export for manual trigger/testing
};
