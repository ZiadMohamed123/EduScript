-- SQL Script to create all tables for EduScript application

-- Create User table
CREATE TABLE IF NOT EXISTS "User" (
  userID UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  profilePicture VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Document table
CREATE TABLE IF NOT EXISTS "Document" (
  documentID UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  userID UUID NOT NULL REFERENCES "User"(userID) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  fileName VARCHAR(255) NOT NULL,
  noOfPages INTEGER DEFAULT 0,
  uploadDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  extractedText TEXT,
  Summary TEXT,
);

-- Create Quiz table
CREATE TABLE IF NOT EXISTS "Quiz" (
  QuizID UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  documentID UUID NOT NULL REFERENCES "Document"(documentID) ON DELETE CASCADE,
  Name VARCHAR(255) NOT NULL,
  DateCreated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
);

-- Create Question table
CREATE TABLE IF NOT EXISTS "Question" (
  QuestionID UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  QuizID UUID NOT NULL REFERENCES "Quiz"(QuizID) ON DELETE CASCADE,
  Text TEXT NOT NULL,
  Type VARCHAR(50),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Answer table
CREATE TABLE IF NOT EXISTS "Answer" (
  AnswerID UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  QuestionID UUID NOT NULL REFERENCES "Question"(QuestionID) ON DELETE CASCADE,
  Text TEXT NOT NULL,
  isCorrect BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Settings table
CREATE TABLE IF NOT EXISTS "Settings" (
  SettingsID UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  userID UUID UNIQUE NOT NULL REFERENCES "User"(userID) ON DELETE CASCADE,
  isNotificationOpen BOOLEAN DEFAULT TRUE,
  isDarkModeOpen BOOLEAN DEFAULT FALSE,
  Language VARCHAR(50) DEFAULT 'English',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_document_userID ON "Document"(userID);
CREATE INDEX IF NOT EXISTS idx_quiz_documentID ON "Quiz"(documentID);
CREATE INDEX IF NOT EXISTS idx_question_quizID ON "Question"(QuizID);
CREATE INDEX IF NOT EXISTS idx_answer_questionID ON "Answer"(QuestionID);
CREATE INDEX IF NOT EXISTS idx_settings_userID ON "Settings"(userID);
CREATE INDEX IF NOT EXISTS idx_user_email ON "User"(email);

-- Add comments to tables for documentation
COMMENT ON TABLE "User" IS 'Stores user account information';
COMMENT ON TABLE "Document" IS 'Stores uploaded documents by users';
COMMENT ON TABLE "Quiz" IS 'Stores quizzes generated from documents';
COMMENT ON TABLE "Question" IS 'Stores questions that belong to quizzes';
COMMENT ON TABLE "Answer" IS 'Stores answer options for questions';
COMMENT ON TABLE "Settings" IS 'Stores user preferences and settings';