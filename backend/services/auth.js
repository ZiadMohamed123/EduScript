import jwt from "jsonwebtoken";
import { User } from "../models/User.js";
import { Settings } from "../models/Settings.js";

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
    if (await User.doesUserExist(email)) {
      return res.status(409).json({
        message: "User already exists",
      });
    }

    // Create user
    const newUser = await User.create({ email, password, name });

    // Create default settings
    await Settings.create(newUser.user_id);

    res.status(201).json({
      message: "User created successfully",
      user: {
        user_id: newUser.user_id,
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
    let user = await User.Login(email, password);
    
    if (!user) {
      return res.status(401).json({
        message: "Invalid email or password",
      });
    }

    // Generate JWT token
    const token = jwt.sign(
      { user_id: user.user_id, email: user.email },
      JWT_SECRET,
      { expiresIn: "7d" }
    );

    res.json({
      message: "Login successful",
      token,
      user: {
        user_id: user.user_id,
        name: user.name,
        email: user.email,
      },
    });
  } catch (error) {
    next(error);
  }
};