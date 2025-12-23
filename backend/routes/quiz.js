// routes/quiz.js
import express from "express";
import { authMiddleware } from "../middleware/auth.js";
import { Quiz } from "../models/Quiz.js";
import { Document } from "../models/Document.js";
import { Question } from "../models/Question.js";
import { Answer } from "../models/Answer.js";

const router = express.Router();

// Debug middleware - Log ALL quiz requests
router.use((req, res, next) => {
  console.log("\n==================== QUIZ ROUTE ====================");
  console.log("📍 Method:", req.method);
  console.log("📍 Path:", req.path);
  console.log("📍 Full URL:", req.originalUrl);
  console.log("📍 Params:", req.params);
  console.log("📍 Query:", req.query);
  console.log("====================================================\n");
  next();
});

// IMPORTANT: Specific routes MUST come before parameterized routes!

// Add a new quiz
router.post("/add", authMiddleware, async (req, res, next) => {
  console.log("🔵 POST /add - Creating new quiz");
  try {
    const user_id = req.user.user_id;
    const { documentID, name, questions } = req.body;
    
    console.log("User ID:", user_id);
    console.log("Document ID:", documentID);
    console.log("Quiz Name:", name);
    console.log("Questions count:", questions?.length);

    if (!documentID || !name) {
      console.log("❌ Validation failed: Missing documentID or name");
      return res.status(400).json({
        success: false,
        message: "Document ID and quiz name are required",
      });
    }

    console.log("Checking if document belongs to user...");
    if (!(await Document.doesDocumentBelongToUser(documentID, user_id))) {
      console.log("❌ Access denied: Document doesn't belong to user");
      return res.status(403).json({
        message: "Document not found or access denied",
      });
    }

    console.log("✅ Document belongs to user, creating quiz...");
    let newQuiz = await Quiz.create(documentID, user_id, { name });
    console.log("✅ Quiz created:", newQuiz.quiz_id);
    
    newQuiz = { ...newQuiz, questions: [] };

    if (questions && Array.isArray(questions) && questions.length > 0) {
      console.log(`Adding ${questions.length} questions...`);
      for (const questionData of questions) {
        if (!questionData.text) continue;

        let newQuestion = await Question.create(newQuiz.quiz_id, {
          text: questionData.text,
        });
        console.log("  ✅ Question created:", newQuestion.question_id);

        newQuestion = { ...newQuestion, answers: [] };

        if (questionData.answers && Array.isArray(questionData.answers)) {
          console.log(`    Adding ${questionData.answers.length} answers...`);
          for (const answerData of questionData.answers) {
            if (!answerData.text) continue;

            const newAnswer = await Answer.create(newQuestion.question_id, {
              text: answerData.text,
              isCorrect: answerData.isCorrect || false,
            });
            console.log("      ✅ Answer created:", newAnswer.answer_id);

            newQuestion.answers.push(newAnswer);
          }
        }

        newQuiz.questions.push(newQuestion);
      }
    }

    console.log("✅ Quiz created successfully with all questions");
    res.status(201).json({
      message: "Quiz created successfully",
      quiz: newQuiz,
    });
  } catch (error) {
    console.error("❌ ERROR in POST /add:", error);
    next(error);
  }
});

// Get ALL quizzes for logged-in user (MUST come BEFORE /:quizID)
router.get("/all", authMiddleware, async (req, res, next) => {
  console.log("🟢 GET /all - Fetching all quizzes");
  try {
    const user_id = req.user.user_id;
    console.log("User ID:", user_id);

    console.log("Calling Quiz.findByUserId...");
    const quizzes = await Quiz.findByUserId(user_id);
    console.log(`✅ Found ${quizzes?.length || 0} quizzes`);

    if (!quizzes || quizzes.length === 0) {
      console.log("No quizzes found, returning empty array");
      return res.json({
        quizzes: [],
        count: 0,
      });
    }

    console.log("Fetching questions for each quiz...");
    const quizzesWithDetails = [];

    for (let i = 0; i < quizzes.length; i++) {
      let quiz = quizzes[i];
      console.log(`  Processing quiz ${i + 1}/${quizzes.length}: ${quiz.name} (${quiz.quiz_id})`);
      
      quiz = { ...quiz, questions: [] };
      
      console.log(`    Fetching questions for quiz ${quiz.quiz_id}...`);
      const questions = await Question.findByQuizId(quiz.quiz_id);
      console.log(`    Found ${questions?.length || 0} questions`);

      for (const question of questions || []) {
        console.log(`      Fetching answers for question ${question.question_id}...`);
        const answers = await Answer.findByQuestionId(question.question_id);
        console.log(`      Found ${answers?.length || 0} answers`);
        
        quiz.questions.push({
          ...question,
          answers: answers || [],
        });
      }

      quizzesWithDetails.push(quiz);
    }

    console.log(`✅ Successfully processed all ${quizzesWithDetails.length} quizzes`);
    console.log("Sending response...");
    
    res.json({
      quizzes: quizzesWithDetails,
      count: quizzesWithDetails.length,
    });
    
    console.log("✅ Response sent successfully");
  } catch (error) {
    console.error("❌ ERROR in GET /all:");
    console.error("Error name:", error.name);
    console.error("Error message:", error.message);
    console.error("Error stack:", error.stack);
    console.error("Full error object:", JSON.stringify(error, null, 2));
    next(error);
  }
});

// Get quizzes by DOCUMENT ID (MUST come BEFORE /:quizID)
router.get("/document/:documentID", authMiddleware, async (req, res, next) => {
  console.log("🟡 GET /document/:documentID - Fetching quizzes by document");
  try {
    const user_id = req.user.user_id;
    const { documentID } = req.params;
    
    console.log("User ID:", user_id);
    console.log("Document ID:", documentID);

    console.log("Fetching quizzes for document...");
    let quizzes = await Quiz.findByDocumentId(documentID);
    console.log(`Found ${quizzes?.length || 0} quizzes`);

    if (!quizzes) {
      console.log("❌ No quizzes found");
      return res.status(404).json({
        message: "Quizzes not found",
      });
    }

    console.log("Verifying document ownership...");
    for (const quiz of quizzes) {
      if (!(await Document.doesDocumentBelongToUser(quiz.document_id, user_id))) {
        console.log("❌ Access denied for quiz:", quiz.quiz_id);
        return res.status(403).json({
          message: "Document not found or access denied",
        });
      }
    }
    console.log("✅ All quizzes verified");

    const quizzesWithDetails = [];

    for (let quiz of quizzes) {
      quiz = { ...quiz, questions: [] };
      const questions = await Question.findByQuizId(quiz.quiz_id);

      for (const question of questions || []) {
        const answers = await Answer.findByQuestionId(question.question_id);
        quiz.questions.push({
          ...question,
          answers: answers || [],
        });
      }

      quizzesWithDetails.push(quiz);
    }

    console.log("✅ Successfully processed quizzes");
    res.json({
      quizzes: quizzesWithDetails,
    });
  } catch (error) {
    console.error("❌ ERROR in GET /document/:documentID:", error);
    next(error);
  }
});

// Get specific quiz by QUIZ ID (MUST come AFTER specific routes)
router.get("/:quizID", authMiddleware, async (req, res, next) => {
  console.log("🟣 GET /:quizID - Fetching specific quiz");
  try {
    const user_id = req.user.user_id;
    const { quizID } = req.params;
    
    console.log("User ID:", user_id);
    console.log("Quiz ID:", quizID);

    console.log("Fetching quiz by ID...");
    let quiz = await Quiz.findById(quizID);

    if (!quiz) {
      console.log("❌ Quiz not found");
      return res.status(404).json({
        message: "Quiz not found",
      });
    }
    console.log("✅ Quiz found:", quiz.name);

    console.log("Verifying document ownership...");
    if (!(await Document.doesDocumentBelongToUser(quiz.document_id, user_id))) {
      console.log("❌ Access denied");
      return res.status(403).json({
        message: "Document not found or access denied",
      });
    }
    console.log("✅ Access verified");

    quiz = { ...quiz, questions: [] };
    
    console.log("Fetching questions...");
    const questions = await Question.findByQuizId(quiz.quiz_id);
    console.log(`Found ${questions?.length || 0} questions`);

    for (const question of questions || []) {
      const answers = await Answer.findByQuestionId(question.question_id);
      quiz.questions.push({
        ...question,
        answers: answers || [],
      });
    }

    console.log("✅ Quiz details loaded successfully");
    res.json({
      quiz: quiz,
    });
  } catch (error) {
    console.error("❌ ERROR in GET /:quizID:", error);
    next(error);
  }
});

// Edit a quiz
router.put("/:quizID", authMiddleware, async (req, res, next) => {
  console.log("🟠 PUT /:quizID - Editing quiz");
  try {
    const user_id = req.user.user_id;
    const { quizID } = req.params;
    const { name, questions } = req.body;

    console.log("User ID:", user_id);
    console.log("Quiz ID:", quizID);
    console.log("New name:", name);

    if (!name) {
      console.log("❌ Validation failed: Missing name");
      return res.status(400).json({
        message: "Quiz name is required",
      });
    }

    const quiz = await Quiz.findById(quizID);

    if (!quiz) {
      console.log("❌ Quiz not found");
      return res.status(404).json({
        message: "Quiz not found",
      });
    }

    if (!(await Document.doesDocumentBelongToUser(quiz.document_id, user_id))) {
      console.log("❌ Access denied");
      return res.status(403).json({
        message: "Document not found or access denied",
      });
    }

    console.log("Updating quiz...");
    let updatedQuiz = await Quiz.update(quizID, { name });
    updatedQuiz = { ...updatedQuiz, questions: [] };

    if (questions && Array.isArray(questions) && questions.length > 0) {
      console.log(`Updating ${questions.length} questions...`);
      for (const questionData of questions) {
        let questionToAdd;

        if (questionData.question_id) {
          if (questionData.text) {
            questionToAdd = await Question.update(questionData.question_id, {
              text: questionData.text,
            });
          } else {
            questionToAdd = await Question.findById(questionData.question_id);
          }
        } else {
          if (!questionData.text) continue;
          questionToAdd = await Question.create(quizID, {
            text: questionData.text,
          });
        }

        questionToAdd = { ...questionToAdd, answers: [] };

        if (questionData.answers && Array.isArray(questionData.answers)) {
          for (const answerData of questionData.answers) {
            let answerToAdd;

            if (answerData.answer_id) {
              answerToAdd = await Answer.update(answerData.answer_id, {
                text: answerData.text,
                isCorrect: answerData.is_correct,
              });
            } else {
              if (!answerData.text) continue;
              answerToAdd = await Answer.create(questionToAdd.question_id, {
                text: answerData.text,
                isCorrect: answerData.is_correct || false,
              });
            }

            questionToAdd.answers.push(answerToAdd);
          }
        } else {
          const existingAnswers = await Answer.findByQuestionId(
            questionToAdd.question_id
          );
          questionToAdd.answers = existingAnswers || [];
        }

        updatedQuiz.questions.push(questionToAdd);
      }
    } else {
      const existingQuestions = await Question.findByQuizId(quizID);
      for (const existingQuestion of existingQuestions || []) {
        const answers = await Answer.findByQuestionId(
          existingQuestion.question_id
        );
        updatedQuiz.questions.push({
          ...existingQuestion,
          answers: answers || [],
        });
      }
    }

    console.log("✅ Quiz updated successfully");
    res.json({
      message: "Quiz updated successfully",
      quiz: updatedQuiz,
    });
  } catch (error) {
    console.error("❌ ERROR in PUT /:quizID:", error);
    next(error);
  }
});

// Delete a quiz
router.delete("/:quizID", authMiddleware, async (req, res, next) => {
  console.log("🔴 DELETE /:quizID - Deleting quiz");
  try {
    const user_id = req.user.user_id;
    const { quizID } = req.params;

    console.log("User ID:", user_id);
    console.log("Quiz ID:", quizID);

    const quiz = await Quiz.findById(quizID);

    if (!quiz) {
      console.log("❌ Quiz not found");
      return res.status(404).json({
        message: "Quiz not found",
      });
    }

    if (!(await Document.doesDocumentBelongToUser(quiz.document_id, user_id))) {
      console.log("❌ Access denied");
      return res.status(403).json({
        message: "Document not found or access denied",
      });
    }

    console.log("Deleting quiz...");
    await Quiz.delete(quizID);

    console.log("✅ Quiz deleted successfully");
    res.json({
      message: "Quiz deleted successfully",
    });
  } catch (error) {
    console.error("❌ ERROR in DELETE /:quizID:", error);
    next(error);
  }
});

export default router;