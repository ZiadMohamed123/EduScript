import express from "express";
import { authMiddleware } from "../middleware/auth.js";
import { Quiz } from "../models/Quiz.js";
import { Document } from "../models/Document.js";
import { Question } from "../models/Question.js";
import { Answer } from "../models/Answer.js";

const router = express.Router();

// Log all requests to this router
router.use((req, res, next) => {
  console.log(`\n🔷 QUIZ ROUTE: ${req.method} ${req.path}`);
  console.log(`   Full URL: ${req.originalUrl}`);
  console.log(`   Base URL: ${req.baseUrl}`);
  console.log(`   Params:`, req.params);
  console.log(`   Route matched: ${req.route?.path || 'NO ROUTE MATCHED YET'}`);
  next();
});

// Add a new quiz
router.post("/add", authMiddleware, async (req, res, next) => {
  console.log("✅ Matched POST /add");
  try {
    const user_id = req.user.user_id;
    const { documentID, name, questions } = req.body;
    
    console.log('💾 Saving quiz:', { name, user_id });

    if (!documentID || !name) {
      return res.status(400).json({
        success: false,
        message: "Document ID and quiz name are required",
      });
    }

    if (!(await Document.doesDocumentBelongToUser(documentID, user_id))) {
      return res.status(403).json({
        message: "Document not found or access denied",
      });
    }

    let newQuiz = await Quiz.create(documentID, user_id, { name });
    newQuiz = { ...newQuiz, questions: [] };

    if (questions && Array.isArray(questions) && questions.length > 0) {
      for (let i = 0; i < questions.length; i++) {
        const questionData = questions[i];
        if (!questionData.text) continue;

        let newQuestion = await Question.create(newQuiz.quiz_id, {
          text: questionData.text,
        });
        newQuestion = { ...newQuestion, answers: [] };

        if (questionData.answers && Array.isArray(questionData.answers)) {
          for (const answerData of questionData.answers) {
            if (!answerData.text) continue;

            const newAnswer = await Answer.create(newQuestion.question_id, {
              text: answerData.text,
              isCorrect: answerData.isCorrect || false,
              userSelected: answerData.userSelected || false, // ← SAVE THIS
            });

            newQuestion.answers.push(newAnswer);
          }
        }

        newQuiz.questions.push(newQuestion);
      }
    }

    res.status(201).json({
      message: "Quiz created successfully",
      quiz: newQuiz,
    });
  } catch (error) {
    console.error("❌ ERROR in POST /add:", error);
    next(error);
  }
});

// Get ALL quizzes (specific route - must come before /:quizID)
router.get("/all", authMiddleware, async (req, res, next) => {
  console.log("✅ Matched GET /all");
  try {
    const user_id = req.user.user_id;
    const quizzes = await Quiz.findByUserId(user_id);

    if (!quizzes || quizzes.length === 0) {
      return res.json({
        quizzes: [],
        count: 0,
      });
    }

    const quizzesWithDetails = [];

    for (let quiz of quizzes) {
      quiz = { ...quiz, questions: [] };
      const questions = await Question.findByQuizId(quiz.quiz_id);

      for (const question of questions || []) {
        const answers = await Answer.findByQuestionId(question.question_id);
        
        // Find which answer was selected by the user
        const selectedAnswer = (answers || []).find(a => a.user_selected === true);
        const userAnswer = selectedAnswer ? selectedAnswer.text : null;
        
        quiz.questions.push({
          ...question,
          userAnswer: userAnswer,
          answers: answers || [],
        });
      }

      quizzesWithDetails.push(quiz);
    }

    res.json({
      quizzes: quizzesWithDetails,
      count: quizzesWithDetails.length,
    });
  } catch (error) {
    console.error("❌ ERROR in GET /all:", error);
    next(error);
  }
});

// Get quizzes by DOCUMENT ID (specific route - must come before /:quizID)
router.get("/document/:documentID", authMiddleware, async (req, res, next) => {
  console.log("✅ Matched GET /document/:documentID");
  try {
    const user_id = req.user.user_id;
    const { documentID } = req.params;

    let quizzes = await Quiz.findByDocumentId(documentID);

    if (!quizzes) {
      return res.status(404).json({
        message: "Quizzes not found",
      });
    }

    for (const quiz of quizzes) {
      if (!(await Document.doesDocumentBelongToUser(quiz.document_id, user_id))) {
        return res.status(403).json({
          message: "Document not found or access denied",
        });
      }
    }

    const quizzesWithDetails = [];

    for (let quiz of quizzes) {
      quiz = { ...quiz, questions: [] };
      const questions = await Question.findByQuizId(quiz.quiz_id);

      for (const question of questions || []) {
        const answers = await Answer.findByQuestionId(question.question_id);
        
        // Find which answer was selected by the user
        const selectedAnswer = (answers || []).find(a => a.user_selected === true);
        const userAnswer = selectedAnswer ? selectedAnswer.text : null;
        
        quiz.questions.push({
          ...question,
          userAnswer: userAnswer,
          answers: answers || [],
        });
      }

      quizzesWithDetails.push(quiz);
    }

    res.json({
      quizzes: quizzesWithDetails,
    });
  } catch (error) {
    console.error("❌ ERROR in GET /document/:documentID:", error);
    next(error);
  }
});

// Edit a quiz (PUT must come before GET)
router.put("/:quizID", authMiddleware, async (req, res, next) => {
  console.log("✅ Matched PUT /:quizID");
  try {
    const user_id = req.user.user_id;
    const { quizID } = req.params;
    const { name, questions } = req.body;

    if (!name) {
      return res.status(400).json({
        message: "Quiz name is required",
      });
    }

    const quiz = await Quiz.findById(quizID);

    if (!quiz) {
      return res.status(404).json({
        message: "Quiz not found",
      });
    }

    if (!(await Document.doesDocumentBelongToUser(quiz.document_id, user_id))) {
      return res.status(403).json({
        message: "Document not found or access denied",
      });
    }

    let updatedQuiz = await Quiz.update(quizID, { name });
    updatedQuiz = { ...updatedQuiz, questions: [] };

    if (questions && Array.isArray(questions) && questions.length > 0) {
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
                userSelected: answerData.user_selected,
              });
            } else {
              if (!answerData.text) continue;
              answerToAdd = await Answer.create(questionToAdd.question_id, {
                text: answerData.text,
                isCorrect: answerData.is_correct || false,
                userSelected: answerData.user_selected || false,
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

    res.json({
      message: "Quiz updated successfully",
      quiz: updatedQuiz,
    });
  } catch (error) {
    console.error("❌ ERROR in PUT /:quizID:", error);
    next(error);
  }
});

// Delete a quiz (DELETE must come before GET)
router.delete("/:quizID", authMiddleware, async (req, res, next) => {
  console.log("✅ Matched DELETE /:quizID");
  try {
    const user_id = req.user.user_id;
    const { quizID } = req.params;

    const quiz = await Quiz.findById(quizID);

    if (!quiz) {
      return res.status(404).json({
        message: "Quiz not found",
      });
    }

    if (!(await Document.doesDocumentBelongToUser(quiz.document_id, user_id))) {
      return res.status(403).json({
        message: "Document not found or access denied",
      });
    }

    await Quiz.delete(quizID);

    res.json({
      message: "Quiz deleted successfully",
    });
  } catch (error) {
    console.error("❌ ERROR in DELETE /:quizID:", error);
    next(error);
  }
});

// Get specific quiz by QUIZ ID - MUST be LAST
router.get("/:quizID", authMiddleware, async (req, res, next) => {
  console.log("✅ Matched GET /:quizID");
  try {
    const user_id = req.user.user_id;
    const { quizID } = req.params;

    console.log(`📖 GET /quiz/${quizID}`);

    let quiz = await Quiz.findById(quizID);

    if (!quiz) {
      return res.status(404).json({
        message: "Quiz not found",
      });
    }

    if (!(await Document.doesDocumentBelongToUser(quiz.document_id, user_id))) {
      return res.status(403).json({
        message: "Document not found or access denied",
      });
    }

    quiz = { ...quiz, questions: [] };
    
    const questions = await Question.findByQuizId(quiz.quiz_id);

    for (const question of questions || []) {
      const answers = await Answer.findByQuestionId(question.question_id);
      
      // Find which answer was selected by the user
      const selectedAnswer = (answers || []).find(a => a.user_selected === true);
      const userAnswer = selectedAnswer ? selectedAnswer.text : null;
      
      quiz.questions.push({
        ...question,
        userAnswer: userAnswer,
        answers: answers || [],
      });
    }

    console.log(`   ✅ Successfully fetched quiz with ${quiz.questions.length} questions`);

    res.json({
      quiz: quiz,
    });
  } catch (error) {
    console.error("❌ ERROR in GET /:quizID:", error);
    next(error);
  }
});

console.log("✅ Quiz routes loaded successfully");

export default router;