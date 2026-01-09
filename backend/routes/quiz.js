import express from "express";
import {
  addQuiz,
  getQuiz,
  editQuiz,
  deleteQuiz,
} from "../services/quiz.js";

const router = express.Router();

// Endpoints
router.post("/add", addQuiz);
router.get("/:documentID", getQuiz);
router.put("/update/:quizID", editQuiz);
router.delete("/delete/:quizID", deleteQuiz);

export default router;