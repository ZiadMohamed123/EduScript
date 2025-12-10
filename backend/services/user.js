import bcrypt from 'bcryptjs';
import { supabase } from '../config/supabase.js';

export const getUser = async (req, res, next) => {
  try {
    const userID = req.user.userID;

    const { data: user, errorUser } = await supabase
      .from('User')
      .select('name, email, profilePicture')
      .eq('userID', userID)
      .single();

    const { data: settings, errorSettings } = await supabase
      .from('Settings')
      .select('*')
      .eq('userID', userID)
      .single();
    
    if (errorUser || !user) {
      return res.status(404).json({
        message: 'User not found'
      });
    }

    if (errorSettings || !settings) {
      settings = {
        isNotificationOpen: true,
        isDarkModeOpen: false,
        language: 'English'
      }
    }

    res.status(200).json({
      user,
      settings
    });
  } catch (errorUser) {
    next(errorUser);
  }
};

export const updateUser = async (req, res, next) => {
  try {
    const userID = req.user.userID;
    const { name, email, profilePicture } = req.body;

    const updateData = {};
    if (name !== undefined) updateData.name = name;
    if (email !== undefined) updateData.email = email;
    if (profilePicture !== undefined) updateData.profilePicture = profilePicture;

    const { data: updatedUser, error } = await supabase
      .from('User')
      .update(updateData)
      .eq('userID', userID)
      .select()
      .single();

    if (error) throw error;

    res.json({
      success: true,
      message: 'Profile updated successfully',
      user: {
        userID: updatedUser.userID,
        name: updatedUser.name,
        email: updatedUser.email,
        profilePicture: updatedUser.profilePicture
      }
    });
  } catch (error) {
    next(error);
  }
};

export const deleteUser = async (req, res, next) => {
  try {
    const userID = req.user.userID;

    // Delete user settings
    await supabase
      .from('Settings')
      .delete()
      .eq('userID', userID);

    // Delete user documents (documents will cascade delete)
    await supabase
      .from('Document')
      .delete()
      .eq('userID', userID);

    // Delete user
    const { error } = await supabase
      .from('User')
      .delete()
      .eq('userID', userID);

    if (error) throw error;

    res.json({
      success: true,
      message: 'User deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

export const toggleNotificationSetting = async (req, res, next) => {
  try {
    const userID = req.user.userID;

    // Get current settings
    const { data: settings, error: getError } = await supabase
      .from('Settings')
      .select('isNotificationOpen')
      .eq('userID', userID)
      .single();

    if (getError) throw getError;

    // Toggle notification
    const { data: updatedSettings, error: updateError } = await supabase
      .from('Settings')
      .update({ isNotificationOpen: !settings.isNotificationOpen })
      .eq('userID', userID)
      .select()
      .single();

    if (updateError) throw updateError;

    res.json({
      success: true,
      message: 'Notification setting updated',
      isNotificationOpen: updatedSettings.isNotificationOpen
    });
  } catch (error) {
    next(error);
  }
};

export const toggleDarkModeSetting = async (req, res, next) => {
  try {
    const userID = req.user.userID;

    // Get current settings
    const { data: settings, error: getError } = await supabase
      .from('Settings')
      .select('isDarkModeOpen')
      .eq('userID', userID)
      .single();

    if (getError) throw getError;

    // Toggle dark mode
    const { data: updatedSettings, error: updateError } = await supabase
      .from('Settings')
      .update({ isDarkModeOpen: !settings.isDarkModeOpen })
      .eq('userID', userID)
      .select()
      .single();

    if (updateError) throw updateError;

    res.json({
      success: true,
      message: 'Dark mode setting updated',
      isDarkModeOpen: updatedSettings.isDarkModeOpen
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
        success: false,
        message: 'Language is required'
      });
    }

    const { data: updatedSettings, error } = await supabase
      .from('Settings')
      .update({ Language: language })
      .eq('userID', userID)
      .select()
      .single();

    if (error) throw error;

    res.json({
      success: true,
      message: 'Language updated successfully',
      language: updatedSettings.Language
    });
  } catch (error) {
    next(error);
  }
};