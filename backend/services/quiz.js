import { Quiz } from "../models/Quiz.js";
import { Document } from "../models/Document.js";
import { Question } from "../models/Question.js";
import { Answer } from "../models/Answer.js";

export const addQuiz = async (req, res, next) => {
  try {
    const userID = req.user.userID;
    const { documentID, name, questions } = req.body;

    // Validate input
    if (!documentID || !name) {
      return res.status(400).json({
        success: false,
        message: "Document ID and quiz name are required",
      });
    }

    // Verify that the quiz belongs to a document owned by the user
    if (!(await Document.doesDocumentBelongToUser(documentID, userID))) {
      return res.status(403).json({
        message: "Document not found or access denied",
      });
    }

    // Create the quiz
    let newQuiz = await Quiz.create(documentID, { name });

    // Add questions and answers if provided
    newQuiz = { ...newQuiz, questions: [] };

    if (questions && Array.isArray(questions) && questions.length > 0) {
      for (const questionData of questions) {
        // Validate question has text
        if (!questionData.text) {
          continue; // Skip invalid questions
        }

        // Create question
        let newQuestion = await Question.create(newQuiz.QuizID, {
          text: questionData.text,
        });

        newQuestion = { ...newQuestion, answers: [] };

        // Add answers if provided
        if (
          questionData.answers &&
          Array.isArray(questionData.answers) &&
          questionData.answers.length > 0
        ) {
          for (const answerData of questionData.answers) {
            // Validate answer has text
            if (!answerData.text) {
              continue; // Skip invalid answers
            }

            const newAnswer = await Answer.create(newQuestion.QuestionID, {
              text: answerData.text,
              isCorrect: answerData.isCorrect || false,
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
    next(error);
  }
};

export const getQuiz = async (req, res, next) => {
  try {
    const userID = req.user.userID;
    const { documentID } = req.params;

    // Get the quiz
    let quizzes = await Quiz.findByDocumentId(documentID);

    if (!quizzes || quizzes.length === 0) {
      return res.status(404).json({
        message: "Quizzes not found",
      });
    }

    for (const quiz of quizzes) {
      // Verify that the quiz belongs to a document owned by the user
      if (!(await Document.doesDocumentBelongToUser(quiz.documentID, userID))) {
        return res.status(403).json({
          message: "Document not found or access denied",
        });
      }
    }

    const quizzesWithDetails = [];

    for (let quiz of quizzes) {
      // Fetch questions and answers
      quiz = { ...quiz, questions: [] };
      const questions = await Question.findByQuizId(quiz.QuizID);

      for (const question of questions || []) {
        const answers = await Answer.findByQuestionId(question.QuestionID);
        quiz.questions.push({
          ...question,
          answers: answers || [],
        });
      }

      quizzesWithDetails.push(quiz);
    }

    res.json({
      success: true,
      quizzes: quizzesWithDetails,
    });
  } catch (error) {
    next(error);
  }
};

export const editQuiz = async (req, res, next) => {
  try {
    const userID = req.user.userID;
    const { quizID } = req.params;
    const { name, questions } = req.body;

    if (!name) {
      return res.status(400).json({
        message: "Quiz name is required",
      });
    }

    // Get the quiz
    const quiz = await Quiz.findById(quizID);

    if (!quiz) {
      return res.status(404).json({
        message: "Quiz not found",
      });
    }

    // Verify that the quiz belongs to a document owned by the user
    if (!(await Document.doesDocumentBelongToUser(quiz.documentID, userID))) {
      return res.status(403).json({
        message: "Document not found or access denied",
      });
    }

    // Update the quiz
    let updatedQuiz = await Quiz.update(quizID, { name });

    // Update questions and answers if provided
    updatedQuiz = { ...updatedQuiz, questions: [] };

    if (questions && Array.isArray(questions) && questions.length > 0) {
      for (const questionData of questions) {
        let questionToAdd;

        // If question has ID, it's an existing question - update it
        if (questionData.QuestionID) {
          // Update existing question
          if (questionData.text) {
            questionToAdd = await Question.update(questionData.QuestionID, {
              text: questionData.text,
            });
          } else {
            questionToAdd = await Question.findById(questionData.QuestionID);
          }
        } else {
          // Create new question
          if (!questionData.text) {
            continue; // Skip invalid questions
          }
          questionToAdd = await Question.create(quizID, {
            text: questionData.text,
          });
        }

        questionToAdd = { ...questionToAdd, answers: [] };

        // Update answers if provided
        if (
          questionData.answers &&
          Array.isArray(questionData.answers) &&
          questionData.answers.length > 0
        ) {
          for (const answerData of questionData.answers) {
            let answerToAdd;

            // If answer has ID, it's an existing answer - update it
            if (answerData.AnswerID) {
              // Update existing answer
              answerToAdd = await Answer.update(answerData.AnswerID, {
                text: answerData.text,
                isCorrect: answerData.isCorrect,
              });
            } else {
              // Create new answer
              if (!answerData.text) {
                continue; // Skip invalid answers
              }
              answerToAdd = await Answer.create(questionToAdd.QuestionID, {
                text: answerData.text,
                isCorrect: answerData.isCorrect || false,
              });
            }

            questionToAdd.answers.push(answerToAdd);
          }
        } else {
          // Fetch existing answers if not updating
          const existingAnswers = await Answer.findByQuestionId(
            questionToAdd.QuestionID
          );
          questionToAdd.answers = existingAnswers || [];
        }

        updatedQuiz.questions.push(questionToAdd);
      }
    } else {
      // Fetch existing questions if not updating
      const existingQuestions = await Question.findByQuizId(quizID);
      for (const existingQuestion of existingQuestions || []) {
        const answers = await Answer.findByQuestionId(
          existingQuestion.QuestionID
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
    next(error);
  }
};

export const deleteQuiz = async (req, res, next) => {
  try {
    const userID = req.user.userID;
    const { quizID } = req.params;

    // Get the quiz
    const quiz = await Quiz.findById(quizID);

    if (!quiz) {
      return res.status(404).json({
        message: "Quiz not found",
      });
    }

    // Verify that the quiz belongs to a document owned by the user
    if (!(await Document.doesDocumentBelongToUser(quiz.documentID, userID))) {
      return res.status(403).json({
        message: "Document not found or access denied",
      });
    }

    // Delete all questions and their answers
    const questions = await Question.findByQuizId(quizID);
    for (const question of questions || []) {
      // Delete all answers for this question
      const answers = await Answer.findByQuestionId(question.QuestionID);
      for (const answer of answers || []) {
        await Answer.delete(answer.AnswerID);
      }
      // Delete the question
      await Question.delete(question.QuestionID);
    }

    // Delete the quiz
    await Quiz.delete(quizID);

    res.json({
      message: "Quiz deleted successfully",
    });
  } catch (error) {
    next(error);
  }
};
