import { supabase } from "../config/supabase.js";

export class Settings {
  static async findByUserId(user_id) {
    const { data, error } = await supabase
      .from("Settings")
      .select("*")
      .eq("user_id", user_id)
      .single();

    if (error) throw error;
    return data;
  }

  static async create(user_id, settingsData = {}) {
    const { data, error } = await supabase
      .from("Settings")
      .insert({
        user_id: user_id,
        is_dark_mode_open: settingsData.isDarkModeOpen ?? false,
        language: settingsData.Language ?? "English",
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  static async update(user_id, updateData) {
    const { data, error } = await supabase
      .from("Settings")
      .update(updateData)
      .eq("user_id", user_id)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  static async toggleDarkMode(user_id) {
    const settings = await this.findByUserId(user_id);
    return await this.update(user_id, {
      is_dark_mode_open: !settings.is_dark_mode_open,
    });
  }

  static async updateLanguage(user_id, language) {
    return await this.update(user_id, { language: language });
  }

  static async delete(user_id) {
    const { error } = await supabase
      .from("Settings")
      .delete()
      .eq("user_id", user_id);

    if (error) throw error;
    return true;
  }
}
