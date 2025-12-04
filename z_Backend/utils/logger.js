const winston = require('winston');
const path = require('path');

// Tạo logger với Winston
const logger = winston.createLogger({
    level: process.env.LOG_LEVEL || 'info',
    format: winston.format.combine(
        winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
        winston.format.errors({ stack: true }),
        winston.format.json()
    ),
    defaultMeta: { service: 'sos-service' },
    transports: [
        // Error logs - chỉ log errors
        new winston.transports.File({
            filename: path.join(__dirname, '../logs/error.log'),
            level: 'error',
            maxsize: 5242880, // 5MB
            maxFiles: 5,
        }),
        // SOS operations logs - tất cả operations
        new winston.transports.File({
            filename: path.join(__dirname, '../logs/sos-operations.log'),
            maxsize: 5242880, // 5MB
            maxFiles: 10,
        }),
        // Console logs (for development)
        new winston.transports.Console({
            format: winston.format.combine(
                winston.format.colorize(),
                winston.format.simple()
            ),
        }),
    ],
});

// Helper functions để log các events cụ thể
logger.logBan = (userId, reason, banUntil) => {
    logger.warn('User banned', {
        userId: userId.toString(),
        reason,
        banUntil: banUntil.toISOString(),
        timestamp: new Date().toISOString(),
    });
};

logger.logQueueExpired = (queueId, volunteerId, caseId) => {
    logger.info('Queue expired', {
        queueId: queueId.toString(),
        volunteerId: volunteerId.toString(),
        caseId: caseId.toString(),
        timestamp: new Date().toISOString(),
    });
};

logger.logAutoCancel = (caseId, reason) => {
    logger.warn('Case auto-cancelled', {
        caseId: caseId.toString(),
        reason,
        timestamp: new Date().toISOString(),
    });
};

module.exports = logger;
