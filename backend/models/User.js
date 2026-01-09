import { supabase } from "../config/supabase.js";
import bcrypt from "bcryptjs";
import fs from "fs";
import path from "path";
import { profilePicturesUploadDir } from "../config/multer.js";

export class User {
  static async doesUserExist(email) {
    const { data, error } = await supabase
      .from("User")
      .select("*")
      .eq("email", email)
      .single();

    return error ? false : true;
  }

  static async Login(email, plainPassword) {
    const { data, error } = await supabase
      .from("User")
      .select("*")
      .eq("email", email)
      .single();

    if (error) return null;

    const isPasswordValid = await bcrypt.compare(plainPassword, data.password);
    return isPasswordValid ? data : null;
  }

  static async findById(user_id) {
    const { data, error } = await supabase
      .from("User")
      .select("user_id, name, email, profile_picture")
      .eq("user_id", user_id)
      .single();

    if (error) throw error;
    return data;
  }

  static async create({ email, password, name }) {
    const hashedPassword = await bcrypt.hash(password, 10);

    const { data, error } = await supabase
      .from("User")
      .insert({
        name,
        email,
        password: hashedPassword,
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  static async update(user_id, updateData) {
    const { data, error } = await supabase
      .from("User")
      .update(updateData)
      .eq("user_id", user_id)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  static async delete(user_id) {
    const { error } = await supabase.from("User").delete().eq("user_id", user_id);

    if (error) throw error;
    return true;
  }

  static async replaceProfilePictureInFile(user_id, newProfilePicture) {
    try {
      await this.deleteProfilePicture(user_id);
      return newProfilePicture.filename;
    } catch (error) {
      if (newProfilePicture) {
        const filePath = path.join(profilePicturesUploadDir, newProfilePicture.filename);
        if (fs.existsSync(filePath)) {
          fs.unlinkSync(filePath);
        }
      }
      throw error;
    }
  }

  static async deleteProfilePicture(user_id) {
    try {
      const userData = await this.findById(user_id);
      if (userData.profile_picture) {
        const filePath = path.join(profilePicturesUploadDir, userData.profile_picture);
        if (fs.existsSync(filePath)) {
          fs.unlinkSync(filePath);
        }
      }
    } catch (error) {
      throw error;
    }
  }
}
