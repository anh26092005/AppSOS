const mongoose = require('mongoose');
const mediaAssetSchema = require('./schemas/mediaAsset.schema');
const geoPointSchema = require('./schemas/geoPoint.schema');

const roleEnum = ['USER', 'TNV_CN', 'TNV_TC', 'ADMIN'];

const addressSchema = new mongoose.Schema(
  {
    line1: { type: String, trim: true },
    ward: { type: String, trim: true },
    district: { type: String, trim: true },
    province: { type: String, trim: true },
    country: { type: String, trim: true },
    location: {
      type: geoPointSchema,
      default: null,
    },
  },
  { _id: false }
);

const userSchema = new mongoose.Schema(
  {
    fullName: {
      type: String,
      required: [true, 'Full name is required'],
      trim: true,
    },
    phone: {
      type: String,
      trim: true,
      default: null,
      // Phone required only for local auth (email/password)
      validate: {
        validator: function (value) {
          // If authProvider is 'local', phone is required
          if (this.authProvider === 'local' && !value) {
            return false;
          }
          return true;
        },
        message: 'Phone number is required for local authentication'
      }
    },
    email: {
      type: String,
      lowercase: true,
      trim: true,
      default: null,
    },
    passwordHash: {
      type: String,
      select: false,
      // Password required only for local auth
      validate: {
        validator: function (value) {
          // If authProvider is 'local', passwordHash is required
          if (this.authProvider === 'local' && !value) {
            return false;
          }
          return true;
        },
        message: 'Password is required for local authentication'
      }
    },
    // Firebase Auth UID for social login (Google, Facebook)
    firebaseUid: {
      type: String,
      unique: true,
      sparse: true, // Allows null values while maintaining uniqueness
      default: null,
    },
    // Authentication provider
    authProvider: {
      type: String,
      enum: ['local', 'google', 'facebook', 'phone'],
      default: 'local',
      required: true,
    },
    // Date of birth (for age calculation)
    dateOfBirth: {
      type: Date,
      default: null,
    },
    roles: {
      type: [String],
      enum: roleEnum,
      default: ['USER'],
      validate: {
        validator(value) {
          return Array.isArray(value) && value.length > 0;
        },
        message: 'At least one role must be assigned',
      },
    },
    avatar: {
      type: mediaAssetSchema,
      default: null,
    },
    bio: {
      type: String,
      trim: true,
      default: null,
      maxlength: [500, 'Bio cannot exceed 500 characters'],
    },
    address: {
      type: addressSchema,
      default: null,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    sosBanUntil: {
      type: Date,
      default: null,
      index: true, // For quick queries to check ban status
    },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);


userSchema.index({ phone: 1 }, { unique: true, sparse: true }); // sparse allows null
userSchema.index({ email: 1 }, { unique: true, sparse: true });
userSchema.index({ firebaseUid: 1 }, { unique: true, sparse: true });
userSchema.index({ 'address.location': '2dsphere' });


userSchema.methods.toJSON = function toJSON() {
  const obj = this.toObject({ getters: true });
  delete obj.passwordHash;
  return obj;
};

module.exports = mongoose.model('User', userSchema);
