import express from "express";
import {
  changeLanguageSetting,
  deleteUser,
  getUser,
  toggleDarkModeSetting,
  toggleNotificationSetting,
  updateUser,
} from "../services/user.js";

const router = express.Router();

// User Endpoints
router.get("/profile", getUser);
router.put("/profile", updateUser);
router.delete("/profile", deleteUser);

// User Settings Endpoints
router.put("/settings/notification", toggleNotificationSetting);
router.put("/settings/darkmode", toggleDarkModeSetting);
router.put("/settings/language", changeLanguageSetting);

export default router;
