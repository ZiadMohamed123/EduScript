import { supabase } from "../config/supabase.js";
import bcrypt from "bcryptjs";
import fs from "fs";
import path from "path";
import { profilePicturesUploadDir, __dirname } from "../config/multer.js";

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

  static async findById(userID) {
    const { data, error } = await supabase
      .from("User")
      .select("userID, name, email, profilePicture")
      .eq("userID", userID)
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

  static async update(userID, updateData) {
    const { data, error } = await supabase
      .from("User")
      .update(updateData)
      .eq("userID", userID)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  static async delete(userID) {
    const { error } = await supabase.from("User").delete().eq("userID", userID);

    if (error) throw error;
    return true;
  }

  static async replaceProfilePictureInFile(userID, newProfilePicture) {
    try {
      await this.deleteProfilePicture(userID);
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

  static async deleteProfilePicture(userID) {
    try {
      const userData = await this.findById(userID);
      if (userData.profilePicture) {
        const filePath = path.join(profilePicturesUploadDir, userData.profilePicture);
        if (fs.existsSync(filePath)) {
          fs.unlinkSync(filePath);
        }
      }
    } catch (error) {
      throw error;
    }
  }
}
