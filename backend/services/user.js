import { User } from "../models/User.js";
import { Settings } from "../models/Settings.js";
import { Document } from "../models/Document.js";
import path from "path";
import fs from "fs";
import { profilePicturesUploadDir } from "../config/multer.js";

export const getUser = async (req, res, next) => {
  try {
    const userID = req.user.userID;

    const user = await User.findById(userID);
    
    if (!user) {
      return res.status(404).json({
        message: "User not found",
      });
    }

    let settings;
    try {
      settings = await Settings.findByUserId(userID);
    } catch (error) {
      settings = {
        isNotificationOpen: true,
        isDarkModeOpen: false,
        Language: "English",
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
    const userID = req.user.userID;
    const { name, email } = req.body;

    const updateData = {};
    if (name !== undefined) updateData.name = name;
    if (email !== undefined) updateData.email = email;
    if (req.file) {
      updateData.profilePicture = await User.replaceProfilePictureInFile(
        userID,
        req.file
      );
    }

    const updatedUser = await User.update(userID, updateData);

    res.json({
      success: true,
      message: "Profile updated successfully",
      user: {
        userID: updatedUser.userID,
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
    const userID = req.user.userID;

    // Delete user profile picture
    await User.deleteProfilePicture(userID);

    // Delete user
    await User.delete(userID);

    res.json({
      message: "User deleted successfully",
    });
  } catch (error) {
    next(error);
  }
};

export const toggleNotificationSetting = async (req, res, next) => {
  try {
    const userID = req.user.userID;

    const updatedSettings = await Settings.toggleNotification(userID);

    res.json({
      message: "Notification setting updated",
      isNotificationOpen: updatedSettings.isNotificationOpen,
    });
  } catch (error) {
    next(error);
  }
};

export const toggleDarkModeSetting = async (req, res, next) => {
  try {
    const userID = req.user.userID;

    const updatedSettings = await Settings.toggleDarkMode(userID);

    res.json({
      message: "Dark mode setting updated",
      isDarkModeOpen: updatedSettings.isDarkModeOpen,
    });
  } catch (error) {
    next(error);
  }
};

export const changeLanguageSetting = async (req, res, next) => {
  try {
    const userID = req.user.userID;
    const { language } = req.body;

    if (!language) {
      return res.status(400).json({
        message: "Language is required",
      });
    }

    const updatedSettings = await Settings.updateLanguage(userID, language);

    res.json({
      message: "Language updated successfully",
      language: updatedSettings.Language,
    });
  } catch (error) {
    next(error);
  }
};

export const getProfilePicture = async (req, res, next) => {
  try {
    const userID = req.user.userID;

    const user = await User.findById(userID);

    const filePath = path.join( profilePicturesUploadDir, user.profilePicture);

    if (!user || !user.profilePicture || !fs.existSync(filePath)) {
      return res.status(404).json({
        message: "Profile picture not found",
      });
    }

    res.sendFile(filePath);
  } catch (error) {
    next(error);
  }
};