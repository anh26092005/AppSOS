require('dotenv').config();
const mongoose = require('mongoose');
const { User } = require('./models');

async function fixAccount() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('Connected to MongoDB');

    const userId = '69098015593b3ba819856918';
    const user = await User.findById(userId);

    if (!user) {
      console.log('❌ User not found!');
      process.exit(1);
    }

    console.log('Current user status:', {
      fullName: user.fullName,
      email: user.email,
      isActive: user.isActive
    });

    // Kích hoạt lại tài khoản
    user.isActive = true;
    await user.save();

    console.log('✅ Account has been activated successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

fixAccount();
