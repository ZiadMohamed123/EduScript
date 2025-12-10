# EduScript Backend API

A Node.js Express backend API for the EduScript mobile application, integrated with Supabase.

## Features

### Authentication Endpoints
- **POST /auth/signup** - Register a new user
- **POST /auth/login** - Login user and receive JWT token

### User Endpoints (Authenticated)
- **GET /user/profile** - Get user profile information
- **PUT /user/profile** - Update user profile
- **DELETE /user/profile** - Delete user account
- **GET /user/settings** - Get user settings
- **PUT /user/settings/notification** - Toggle notification settings
- **PUT /user/settings/darkmode** - Toggle dark mode
- **PUT /user/settings/language** - Update language preference

### Document Endpoints (Authenticated)
- **POST /document/add** - Add a new document
- **PUT /document/edit/:documentID** - Edit document metadata
- **DELETE /document/delete/:documentID** - Delete a document
- **GET /document/metadata** - Get all documents metadata
- **GET /document/:documentID** - Get complete document by ID

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
