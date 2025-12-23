-- SQL Script to create all tables for EduScript application with snake_case naming convention

-- Create User table
CREATE TABLE IF NOT EXISTS "User" (
  user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  profile_picture VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Document table
CREATE TABLE IF NOT EXISTS "Document" (
  document_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES "User"(user_id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  file_name VARCHAR(255) NOT NULL,
  no_of_pages INTEGER DEFAULT 0,
  upload_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  extracted_text TEXT,
  summary TEXT
);

-- Create Quiz table
CREATE TABLE IF NOT EXISTS "Quiz" (
  quiz_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id UUID NOT NULL REFERENCES "Document"(document_id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  date_created TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Question table
CREATE TABLE IF NOT EXISTS "Question" (
  question_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quiz_id UUID NOT NULL REFERENCES "Quiz"(quiz_id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Answer table
CREATE TABLE IF NOT EXISTS "Answer" (
  answer_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id UUID NOT NULL REFERENCES "Question"(question_id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  is_correct BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Settings table
CREATE TABLE IF NOT EXISTS "Settings" (
  settings_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES "User"(user_id) ON DELETE CASCADE,
  is_dark_mode_open BOOLEAN DEFAULT FALSE,
  language VARCHAR(50) DEFAULT 'English',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_document_user_id ON "Document"(user_id);
CREATE INDEX IF NOT EXISTS idx_quiz_document_id ON "Quiz"(document_id);
CREATE INDEX IF NOT EXISTS idx_question_quiz_id ON "Question"(quiz_id);
CREATE INDEX IF NOT EXISTS idx_answer_question_id ON "Answer"(question_id);
CREATE INDEX IF NOT EXISTS idx_settings_user_id ON "Settings"(user_id);
CREATE INDEX IF NOT EXISTS idx_user_email ON "User"(email);

-- Add comments to tables for documentation
COMMENT ON TABLE "User" IS 'Stores user account information';
COMMENT ON TABLE "Document" IS 'Stores uploaded documents by users';
COMMENT ON TABLE "Quiz" IS 'Stores quizzes generated from documents';
COMMENT ON TABLE "Question" IS 'Stores questions that belong to quizzes';
COMMENT ON TABLE "Answer" IS 'Stores answer options for questions';
COMMENT ON TABLE "Settings" IS 'Stores user preferences and settings';