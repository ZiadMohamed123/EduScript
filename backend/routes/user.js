import express from "express";
import {
  changeLanguageSetting,
  deleteUser,
  getUser,
  getProfilePicture,
  toggleDarkModeSetting,
  updateUser,
} from "../services/user.js";
import { profilePicturesUpload } from "../config/multer.js";

const router = express.Router();

// User Endpoints
router.get("/", getUser);
router.get("/profile-picture", getProfilePicture);
router.put("/update", profilePicturesUpload.single("profilePicture"), updateUser);
router.delete("/delete", deleteUser);

// Settings Endpoints
router.put("/settings/darkmode", toggleDarkModeSetting);
router.put("/settings/language", changeLanguageSetting);

export default router;
