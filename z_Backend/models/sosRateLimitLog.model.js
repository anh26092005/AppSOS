const mongoose = require('mongoose');

const sosRateLimitLogSchema = new mongoose.Schema(
    {
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true,
            index: true,
        },
        createdAt: {
            type: Date,
            default: Date.now,
            expires: 600, // TTL index: tự động xóa sau 10 phút (600 seconds)
        },
    },
    {
        timestamps: false,
        versionKey: false,
        collection: 'sos_rate_limit_logs',
    }
);

// Index để query nhanh theo userId và createdAt
sosRateLimitLogSchema.index({ userId: 1, createdAt: -1 });

module.exports = mongoose.model('SosRateLimitLog', sosRateLimitLogSchema);
