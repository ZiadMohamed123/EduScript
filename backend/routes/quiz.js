import express from "express";
import {
  addQuiz,
  deleteQuiz,
  editQuiz,
  getQuiz,
  getQuizzesByDocumentID,
  getQuizzesByUserID,
} from "../services/quiz.js";

const router = express.Router();

//Quiz Endpoints
router.post("/add", addQuiz);
router.get("/all", getQuizzesByUserID);
router.get("/document/:documentID", getQuizzesByDocumentID);
router.put("/:quizID", editQuiz);
router.delete("/:quizID", deleteQuiz);
// MUST be LAST
router.get("/:quizID", getQuiz);

export default router;
