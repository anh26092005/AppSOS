const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');

const envPaths = [
    path.join(__dirname, '../.env'),
    path.join(process.cwd(), '.env'),
];

for (const p of envPaths) {
    const result = dotenv.config({ path: p });
    if (!result.error) break;
}

const connectDB = async () => {
    try {
        const conn = await mongoose.connect(process.env.MONGO_URI);
        console.log(`MongoDB Connected: ${conn.connection.host}`);
    } catch (error) {
        console.error(`Error: ${error.message}`);
        process.exit(1);
    }
};

const unbanUser = async () => {
    try {
        await connectDB();
        const User = require('../models/user.model');

        const userId = '69104cd9f7c23b7c27c38e19'; // ID from logs

        console.log(`Unbanning user ${userId}...`);

        const result = await User.updateOne(
            { _id: userId },
            { $unset: { sosBanUntil: 1 } }
        );

        if (result.modifiedCount > 0) {
            console.log('✅ User unbanned successfully');
        } else {
            console.log('ℹ️ User was not banned or user not found');
        }

        process.exit(0);
    } catch (error) {
        console.error('❌ Error unbanning user:', error);
        process.exit(1);
    }
};

unbanUser();
