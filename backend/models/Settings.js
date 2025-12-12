import { supabase } from "../config/supabase.js";

export class Settings {
  static async findByUserId(userID) {
    const { data, error } = await supabase
      .from("Settings")
      .select("*")
      .eq("userID", userID)
      .single();

    if (error) throw error;
    return data;
  }

  static async create(userID, settingsData = {}) {
    const { data, error } = await supabase
      .from("Settings")
      .insert({
        userID,
        isNotificationOpen: settingsData.isNotificationOpen ?? true,
        isDarkModeOpen: settingsData.isDarkModeOpen ?? false,
        Language: settingsData.Language ?? "English",
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  static async update(userID, updateData) {
    const { data, error } = await supabase
      .from("Settings")
      .update(updateData)
      .eq("userID", userID)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  static async toggleNotification(userID) {
    const settings = await this.findByUserId(userID);
    return await this.update(userID, {
      isNotificationOpen: !settings.isNotificationOpen,
    });
  }

  static async toggleDarkMode(userID) {
    const settings = await this.findByUserId(userID);
    return await this.update(userID, {
      isDarkModeOpen: !settings.isDarkModeOpen,
    });
  }

  static async updateLanguage(userID, language) {
    return await this.update(userID, { Language: language });
  }

  static async delete(userID) {
    const { error } = await supabase
      .from("Settings")
      .delete()
      .eq("userID", userID);

    if (error) throw error;
    return true;
  }
}
