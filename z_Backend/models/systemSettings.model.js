const mongoose = require('mongoose');

/**
 * SystemSettings Model
 * Singleton collection for storing system-wide configuration
 * Always contains exactly one document
 */
const systemSettingsSchema = new mongoose.Schema(
  {
    // Demo Mode: When enabled, only users with isDemoAllowed=true can use SOS APIs
    demoMode: {
      type: Boolean,
      default: false,
      required: true,
    },
    // Future settings can be added here:
    // maintenanceMode: Boolean,
    // maxActiveSOSCases: Number,
    // etc.
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

// Ensure only one settings document exists
systemSettingsSchema.statics.getSettings = async function () {
  let settings = await this.findOne();
  if (!settings) {
    // Create default settings if none exist
    settings = await this.create({ demoMode: false });
  }
  return settings;
};

// Update settings helper
systemSettingsSchema.statics.updateSettings = async function (updates) {
  let settings = await this.getSettings();
  Object.assign(settings, updates);
  await settings.save();
  return settings;
};

module.exports = mongoose.model('SystemSettings', systemSettingsSchema);
