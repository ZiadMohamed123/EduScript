# EduScript Backend API

A Node.js Express backend API for the EduScript mobile application, integrated with Supabase.

## Features

### Authentication Endpoints
- **POST /auth/signup** - Register a new user
- **POST /auth/login** - Login user and receive JWT token

### User Endpoints (Authenticated)
- **GET /user** - Get user profile and settings information
- **GET /user/profile-picture** - Get user's profile picture
- **PUT /user/update** - Update user profile (with profile picture upload)
- **DELETE /user/delete** - Delete user account (and associated profile picture)
- **PUT /user/settings/darkmode** - Toggle dark mode
- **PUT /user/settings/language** - Update language preference

### Document Endpoints (Authenticated)
- **POST /document/add** - Add a new document
- **PUT /document/edit/:documentID** - Edit document metadata
- **DELETE /document/delete/:documentID** - Delete a document
- **GET /document/allDocsMetaData** - Get all documents metadata
- **GET /document/:documentID** - Get complete document by ID

### Quiz Endpoints (Authenticated)
- **GET /quiz/:quizID** - Get quiz by ID
- **PUT /quiz/update/:quizID** - Edit quiz name
- **DELETE /quiz/delete/:quizID** - Delete quiz

## Installation

1. Clone the repository and navigate to the backend directory:
```bash
cd backend
```

2. Install dependencies:
```bash
npm install
```

3. Create a `.env` file:
```bash
touch .env
```

4. Update `.env` with your Supabase credentials:
```
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
JWT_SECRET=your_secure_jwt_secret
PORT=5000
NODE_ENV=development
```

## Running the Server

### Development Mode (with auto-reload)
```bash
npm run dev
```

### Production Mode
```bash
npm start
```

The server will run on `http://localhost:5000` by default.

## Authentication

Protected endpoints require a JWT token in the Authorization header:
```
Authorization: Bearer <your_jwt_token>
```

Tokens are valid for 7 days from the time of issue.

## File Uploads

### Profile Pictures
- Upload with **PUT /user/update** endpoint (multipart/form-data with `profilePicture` field)
- Old profile pictures are automatically replaced when updating
- Profile pictures are deleted when the user account is deleted
- Retrieved with **GET /user/profile-picture** endpoint

### Documents
Similar to profile pictures:
- Upload with **POST /document/add** endpoint
- Update with **PUT /document/edit/:documentID** endpoint
- Files are stored in `/uploads/documents/`
- Automatic cleanup on deletion

## Error Handling

All responses follow a consistent format:
```json
{
  "message": "Description",
  "data": {} // Optional
}
```

## Development

The API uses:
- **Express.js** - Web framework
- **Supabase** - Backend database and authentication
- **bcryptjs** - Password hashing
- **jsonwebtoken** - JWT token generation and verification
- **CORS** - Cross-origin resource sharing
- **dotenv** - Environment variable management

### Architecture

The backend follows a layered architecture:

1. **Models** (`/models`) - Direct database interaction with Supabase
   - Static methods for CRUD operations

2. **Services** (`/services`) - Business logic
   - Uses models for database operations

3. **Routes** (`/routes`) - API endpoints
   - Delegates to services

4. **Middleware** (`/middleware`) - Request processing
   - authMiddleware for JWT verification