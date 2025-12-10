import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { supabase } from "../config/supabase.js";

const JWT_SECRET = process.env.JWT_SECRET;

export const signUp = async (req, res, next) => {
  try {
    const { email, password, name } = req.body;

    // Validate input
    if (!email || !password || !name) {
      return res.status(400).json({
        message: "Email, password, and name are required",
      });
    }

    // Check if user already exists
    const { data: existingUser } = await supabase
      .from("User")
      .select("userID")
      .eq("email", email)
      .single();

    if (existingUser) {
      return res.status(409).json({
        message: "User already exists",
      });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create user
    const { data: newUser, error } = await supabase
      .from("User")
      .insert({
        name,
        email,
        password: hashedPassword,
      })
      .select()
      .single();

    if (error) throw error;

    // Create default settings
    await supabase.from("Settings").insert({
      userID: newUser.userID,
      isNotificationOpen: true,
      isDarkModeOpen: false,
      Language: "English",
    });

    res.status(201).json({
      message: "User created successfully",
      user: {
        userID: newUser.userID,
        name: newUser.name,
        email: newUser.email,
      },
    });
  } catch (error) {
    next(error);
  }
};

export const logIn = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    // Validate input
    if (!email || !password) {
      return res.status(400).json({
        message: "Email and password are required",
      });
    }

    // Find user
    const { data: user, error } = await supabase
      .from("User")
      .select("*")
      .eq("email", email)
      .single();

    if (error || !user) {
      return res.status(401).json({
        message: "Invalid email or password",
      });
    }

    // Verify password
    const isPasswordValid = await bcrypt.compare(password, user.password);

    if (!isPasswordValid) {
      return res.status(401).json({
        message: "Invalid email or password",
      });
    }

    // Generate JWT token
    const token = jwt.sign(
      { userID: user.userID, email: user.email },
      JWT_SECRET,
      { expiresIn: "7d" }
    );

    res.json({
      message: "Login successful",
      token,
      user: {
        userID: user.userID,
        name: user.name,
        email: user.email,
      },
    });
  } catch (error) {
    next(error);
  }
};
