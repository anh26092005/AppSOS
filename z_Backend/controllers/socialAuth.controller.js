const AppError = require('../utils/appError');
const { signAccessToken } = require('../utils/jwt');
const { User } = require('../models');

/**
 * Social Login - Register or authenticate users from Firebase Auth
 * (Google, Facebook, Phone OTP)
 * 
 * Request body:
 * {
 *   firebaseUid: string (required),
 *   displayName: string (required),
 *   email: string (optional),
 *   photoURL: string (optional),
 *   provider: 'google' | 'facebook' | 'phone' (required)
 * }
 */
const socialLogin = async (req, res, next) => {
    try {
        const { firebaseUid, displayName, email, photoURL, provider } = req.body;

        // Validation
        if (!firebaseUid) {
            throw new AppError('Firebase UID is required', 400);
        }
        if (!displayName) {
            throw new AppError('Display name is required', 400);
        }
        if (!provider || !['google', 'facebook', 'phone'].includes(provider)) {
            throw new AppError('Valid provider is required (google, facebook, phone)', 400);
        }

        // Check if user exists by Firebase UID
        let user = await User.findOne({ firebaseUid });

        if (user) {
            // Existing user - update info if changed
            let updated = false;

            if (user.fullName !== displayName) {
                user.fullName = displayName;
                updated = true;
            }

            if (email && user.email !== email) {
                user.email = email;
                updated = true;
            }

            if (photoURL && (!user.avatar || user.avatar.url !== photoURL)) {
                user.avatar = {
                    bucket: 'external', // Social login photos are external, not in S3
                    key: photoURL, // Use URL as key since it's external
                    url: photoURL,
                    thumbnailUrl: photoURL,
                    type: 'image',
                };
                updated = true;
            }

            if (updated) {
                await user.save();
            }

            // Generate token
            const token = signAccessToken({ id: user._id, roles: user.roles });

            return res.json({
                success: true,
                token,
                user: {
                    _id: user._id,
                    fullName: user.fullName,
                    email: user.email,
                    phone: user.phone,
                    roles: user.roles,
                    avatar: user.avatar,
                    authProvider: user.authProvider,
                },
                isNewUser: false,
            });
        }

        // Check for existing user by email (might have registered via email/password)
        if (email) {
            user = await User.findOne({ email });

            if (user) {
                // Link Firebase UID to existing account
                user.firebaseUid = firebaseUid;

                // Update provider if it was local
                if (user.authProvider === 'local') {
                    user.authProvider = provider;
                }

                // Update photo if available
                if (photoURL) {
                    user.avatar = {
                        bucket: 'external',
                        key: photoURL,
                        url: photoURL,
                        thumbnailUrl: photoURL,
                        type: 'image',
                    };
                }

                await user.save();

                const token = signAccessToken({ id: user._id, roles: user.roles });

                return res.json({
                    success: true,
                    token,
                    user: {
                        _id: user._id,
                        fullName: user.fullName,
                        email: user.email,
                        phone: user.phone,
                        roles: user.roles,
                        avatar: user.avatar,
                        authProvider: user.authProvider,
                    },
                    isNewUser: false,
                    linked: true, // Indicates account was linked
                });
            }
        }

        // Create new user - handle race condition with try-catch
        const newUserData = {
            firebaseUid,
            fullName: displayName,
            email: email || null,
            phone: null, // Social login doesn't provide phone
            authProvider: provider,
            roles: ['USER'],
        };

        // Add avatar if provided
        if (photoURL) {
            newUserData.avatar = {
                bucket: 'external',
                key: photoURL,
                url: photoURL,
                thumbnailUrl: photoURL,
                type: 'image',
            };
        }

        let newUser;
        try {
            // Try to create user directly (fastest path)
            newUser = await User.create(newUserData);
        } catch (error) {
            // If duplicate key error (race condition), find the existing user
            if (error.code === 11000) {
                console.log('⚠️  Race condition detected, finding existing user...');
                newUser = await User.findOne({ firebaseUid });

                if (!newUser) {
                    // This shouldn't happen, but if it does, try by email
                    if (email) {
                        newUser = await User.findOne({ email });
                    }
                }

                if (!newUser) {
                    // Still not found? Re-throw error
                    throw error;
                }
            } else {
                // Other error, re-throw
                throw error;
            }
        }

        // Generate token
        const token = signAccessToken({ id: newUser._id, roles: newUser.roles });

        res.status(201).json({
            success: true,
            token,
            user: {
                _id: newUser._id,
                fullName: newUser.fullName,
                email: newUser.email,
                phone: newUser.phone,
                roles: newUser.roles,
                avatar: newUser.avatar,
                authProvider: newUser.authProvider,
            },
            isNewUser: true,
        });
    } catch (error) {
        next(error);
    }
};

module.exports = {
    socialLogin,
};
