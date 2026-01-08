import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import authRoutes from './routes/auth.js';
import userRoutes from './routes/user.js';
import documentRoutes from './routes/document.js';
import quizRoutes from './routes/quiz.js';
import { authMiddleware } from './middleware/auth.js';

dotenv.config({filepath: `./.env.${process.env.NODE_ENV || 'development'}`});

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/auth', authRoutes);
app.use('/user', authMiddleware, userRoutes);
app.use('/document', authMiddleware, documentRoutes);
app.use('/quiz', authMiddleware, quizRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  res.status(err.status || 500).json({
    message: err.message || 'Internal server error',
    error: process.env.NODE_ENV === 'development' ? err : undefined
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`Server running on port: ${PORT}`);
});