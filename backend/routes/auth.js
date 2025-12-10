import express from "express";
import { logIn, signUp } from "../services/auth.js";

const router = express.Router();

// Endpoints
router.post("/signup", signUp);
router.post("/login", logIn);

export default router;
