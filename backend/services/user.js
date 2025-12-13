import { User } from "../models/User.js";
import { Settings } from "../models/Settings.js";
import { Document } from "../models/Document.js";
import path from "path";
import fs from "fs";
import { profilePicturesUploadDir } from "../config/multer.js";

export const getUser = async (req, res, next) => {
  try {
    const user_id = req.user.user_id;

    const user = await User.findById(user_id);
    
    if (!user) {
      return res.status(404).json({
        message: "User not found",
      });
    }

    let settings;
    try {
      settings = await Settings.findByUserId(user_id);
    } catch (error) {
      settings = {
        is_notification_open: true,
        is_dark_mode_open: false,
        language: "English",
      };
    }

    res.status(200).json({
      user,
      settings,
    });
  } catch (error) {
    next(error);
  }
};

export const updateUser = async (req, res, next) => {
  try {
    const user_id = req.user.user_id;
    const { name, email } = req.body;

    const updateData = {};
    if (name !== undefined) updateData.name = name;
    if (email !== undefined) updateData.email = email;
    if (req.file) {
      updateData.profile_picture = await User.replaceProfilePictureInFile(
        user_id,
        req.file
      );
    }

    const updatedUser = await User.update(user_id, updateData);

    res.json({
      message: "Profile updated successfully",
      user: {
        user_id: updatedUser.user_id,
        name: updatedUser.name,
        email: updatedUser.email,
      },
    });
  } catch (error) {
    next(error);
  }
};

export const deleteUser = async (req, res, next) => {
  try {
    const user_id = req.user.user_id;

    // Delete user profile picture
    await User.deleteProfilePicture(user_id);

    // Delete user
    await User.delete(user_id);

    res.json({
      message: "User deleted successfully",
    });
  } catch (error) {
    next(error);
  }
};

export const toggleNotificationSetting = async (req, res, next) => {
  try {
    const user_id = req.user.user_id;

    const updatedSettings = await Settings.toggleNotification(user_id);

    res.json({
      message: "Notification setting updated",
      is_notification_open: updatedSettings.is_notification_open,
    });
  } catch (error) {
    next(error);
  }
};

export const toggleDarkModeSetting = async (req, res, next) => {
  try {
    const user_id = req.user.user_id;

    const updatedSettings = await Settings.toggleDarkMode(user_id);

    res.json({
      message: "Dark mode setting updated",
      is_dark_mode_open: updatedSettings.is_dark_mode_open,
    });
  } catch (error) {
    next(error);
  }
};

export const changeLanguageSetting = async (req, res, next) => {
  try {
    const user_id = req.user.user_id;
    const { language } = req.body;

    if (!language) {
      return res.status(400).json({
        message: "Language is required",
      });
    }

    const updatedSettings = await Settings.updateLanguage(user_id, language);

    res.json({
      message: "Language updated successfully",
      language: updatedSettings.language,
    });
  } catch (error) {
    next(error);
  }
};

export const getProfilePicture = async (req, res, next) => {
  try {
    const user_id = req.user.user_id;

    const user = await User.findById(user_id);

    const filePath = path.join( profilePicturesUploadDir, user.profile_picture);

    if (!user || !user.profile_picture || !fs.existsSync(filePath)) {
      return res.status(404).json({
        message: "Profile picture not found",
      });
    }

    res.sendFile(filePath);
  } catch (error) {
    next(error);
  }
};