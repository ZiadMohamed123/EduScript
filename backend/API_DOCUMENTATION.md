# EduScript API Documentation

This document provides detailed information about all API endpoints, including the exact JSON format required for each request, and clearly indicates which fields are required (✅) and which are optional (❌).

---

## 📋 Table of Contents
1. [Authentication Endpoints](#authentication-endpoints)
2. [User Endpoints](#user-endpoints)
3. [Document Endpoints](#document-endpoints)
4. [Quiz Endpoints](#quiz-endpoints)

---

## Authentication Endpoints

### 1. Sign Up
**Endpoint:** `POST /auth/signup`

**Description:** Create a new user account.

**Request Headers:**
```json
{
  "Content-Type": "application/json"
}
```

**Request Body:**
```json
{
  "email": "user@example.com",        // ✅ Required (string)
  "password": "password123",          // ✅ Required (string)
  "name": "John Doe"                  // ✅ Required (string)
}
```

**Response (201 Created):**
```json
{
  "message": "User created successfully",
  "user": {
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "John Doe",
    "email": "user@example.com"
  }
}
```

**Error Responses:**
- **400 Bad Request:** Missing required fields (email, password, or name)
- **409 Conflict:** User with this email already exists

---

### 2. Login
**Endpoint:** `POST /auth/login`

**Description:** Authenticate user and receive JWT token.

**Request Headers:**
```json
{
  "Content-Type": "application/json"
}
```

**Request Body:**
```json
{
  "email": "user@example.com",        // ✅ Required (string)
  "password": "password123"           // ✅ Required (string)
}
```

**Response (200 OK):**
```json
{
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "John Doe",
    "email": "user@example.com"
  }
}
```

**Error Responses:**
- **400 Bad Request:** Missing email or password
- **401 Unauthorized:** Invalid email or password

---

## User Endpoints

### 3. Get User Profile
**Endpoint:** `GET /user/`

**Description:** Retrieve user profile and settings.

**Request Headers:**
```json
{
  "Authorization": "Bearer <JWT_TOKEN>"
}
```

**Request Body:** None

**Response (200 OK):**
```json
{
  "user": {
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "John Doe",
    "email": "user@example.com",
    "profile_picture": "filename.jpg"
  },
  "settings": {
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "is_dark_mode_open": false,
    "language": "English"
  }
}
```

**Error Responses:**
- **401 Unauthorized:** Missing or invalid JWT token
- **404 Not Found:** User not found

---

### 4. Update User Profile
**Endpoint:** `PUT /user/update`

**Description:** Update user name, email, and/or profile picture.

**Request Headers:**
```json
{
  "Authorization": "Bearer <JWT_TOKEN>",
  "Content-Type": "multipart/form-data"
}
```

**Request Body (multipart/form-data):**
```
name: "Jane Doe"                    // ❌ Optional (string)
email: "newemail@example.com"       // ❌ Optional (string)
profilePicture: <file>              // ❌ Optional (file)
```

**Response (200 OK):**
```json
{
  "message": "Profile updated successfully",
  "user": {
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Jane Doe",
    "email": "newemail@example.com"
  }
}
```

**Error Responses:**
- **401 Unauthorized:** Missing or invalid JWT token
- **500 Internal Server Error:** Update failed

---

### 5. Get Profile Picture
**Endpoint:** `GET /user/profile-picture`

**Description:** Gets user's profile picture.

**Request Headers:**
```json
{
  "Authorization": "Bearer <JWT_TOKEN>"
}
```

**Request Body:** None

**Response (200 OK):** Binary file data (image)

**Error Responses:**
- **401 Unauthorized:** Missing or invalid JWT token
- **404 Not Found:** Profile picture not found

---

### 6. Delete User Account
**Endpoint:** `DELETE /user/delete`

**Description:** Permanently delete user account and all associated data.

**Request Headers:**
```json
{
  "Authorization": "Bearer <JWT_TOKEN>"
}
```

**Request Body:** None

**Response (200 OK):**
```json
{
  "message": "User deleted successfully"
}
```

**Error Responses:**
- **401 Unauthorized:** Missing or invalid JWT token

---

### 7. Toggle Dark Mode Setting
**Endpoint:** `PUT /user/settings/darkmode`

**Description:** Toggle dark mode setting on/off.

**Request Headers:**
```json
{
  "Authorization": "Bearer <JWT_TOKEN>",
  "Content-Type": "application/json"
}
```

**Request Body:** None (endpoint toggles the current state)

**Response (200 OK):**
```json
{
  "message": "Dark mode setting updated",
  "is_dark_mode_open": true
}
```

**Error Responses:**
- **401 Unauthorized:** Missing or invalid JWT token

---

### 8. Change Language Setting
**Endpoint:** `PUT /user/settings/language`

**Description:** Change user's language preference.

**Request Headers:**
```json
{
  "Authorization": "Bearer <JWT_TOKEN>",
  "Content-Type": "application/json"
}
```

**Request Body:**
```json
{
  "language": "English"               // ✅ Required (string)
}
```

**Response (200 OK):**
```json
{
  "message": "Language updated successfully",
  "language": "English"
}
```

**Error Responses:**
- **400 Bad Request:** Missing language field
- **401 Unauthorized:** Missing or invalid JWT token

---

## Document Endpoints

### 9. Add Document
**Endpoint:** `POST /document/add`

**Description:** Upload a new document.

**Request Headers:**
```json
{
  "Authorization": "Bearer <JWT_TOKEN>",
  "Content-Type": "multipart/form-data"
}
```

**Request Body (multipart/form-data):**
```
name: "Document Title"              // ✅ Required (string)
document: <file>                    // ✅ Required (file)
noOfPages: 10                       // ❌ Optional (number)
extractedText: "Full document..."   // ❌ Optional (string)
summary: "Document summary..."      // ❌ Optional (string)
```

**Response (201 Created):**
```json
{
  "message": "Document added successfully",
  "document": {
    "document_id": "660e8400-e29b-41d4-a716-446655440001",
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Document Title",
    "file_name": "uuid-filename.pdf",
    "no_of_pages": 10,
    "extracted_text": "Full document...",
    "summary": "Document summary...",
    "created_at": "2024-01-15T10:30:00Z",
  }
}
```

**Error Responses:**
- **400 Bad Request:** Missing name or file
- **401 Unauthorized:** Missing or invalid JWT token
- **500 Internal Server Error:** File upload failed

---

### 10. Get All Documents Metadata
**Endpoint:** `GET /document/allDocsMetaData`

**Description:** Retrieve metadata for all documents belonging to the user.

**Request Headers:**
```json
{
  "Authorization": "Bearer <JWT_TOKEN>"
}
```

**Request Body:** None

**Response (200 OK):**
```json
{
  "documents": [
    {
      "document_id": "660e8400-e29b-41d4-a716-446655440001",
      "user_id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "Document Title",
      "file_name": "uuid-filename.pdf",
      "no_of_pages": 10,
      "extracted_text": "Full document...",
      "summary": "Document summary...",
      "created_at": "2024-01-15T10:30:00Z",
    }
  ],
  "count": 1
}
```

**Error Responses:**
- **401 Unauthorized:** Missing or invalid JWT token

---

### 11. Get Document File
**Endpoint:** `GET /document/:documentID`

**Description:** Gets a document file by ID.

**Request Headers:**
```json
{
  "Authorization": "Bearer <JWT_TOKEN>"
}
```

**URL Parameters:**
```
documentID: "660e8400-e29b-41d4-a716-446655440001"  // ✅ Required (UUID string)
```

**Request Body:** None

**Response (200 OK):** Binary file data (image)

**Error Responses:**
- **401 Unauthorized:** Missing or invalid JWT token
- **404 Not Found:** Document not found or access denied

---

### 12. Update Document
**Endpoint:** `PUT /document/edit/:documentID`

**Description:** Update document details and/or file.

**Request Headers:**
```json
{
  "Authorization": "Bearer <JWT_TOKEN>",
  "Content-Type": "multipart/form-data"
}
```

**URL Parameters:**
```
documentID: 1                       // ✅ Required (integer)
```

**Request Body (multipart/form-data):**
```
name: "Updated Title"               // ❌ Optional (string)
noOfPages: 15                       // ❌ Optional (number)
extractedText: "Updated text..."    // ❌ Optional (string)
summary: "Updated summary..."       // ❌ Optional (string)
newDocument: <file>                 // ❌ Optional (file)
```

**Response (200 OK):**
```json
{
  "message": "Document updated successfully",
  "document": {
    "document_id": "660e8400-e29b-41d4-a716-446655440001",
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Updated Title",
    "file_name": "uuid-filename.pdf",
    "no_of_pages": 15,
    "extracted_text": "Updated text...",
    "summary": "Updated summary...",
    "created_at": "2024-01-15T10:30:00Z",
  }
}
```

**Error Responses:**
- **401 Unauthorized:** Missing or invalid JWT token
- **404 Not Found:** Document not found or access denied
- **500 Internal Server Error:** Update failed

---

### 13. Delete Document
**Endpoint:** `DELETE /document/delete/:documentID`

**Description:** Delete a document.

**Request Headers:**
```json
{
  "Authorization": "Bearer <JWT_TOKEN>"
}
```

**URL Parameters:**
```
documentID: "660e8400-e29b-41d4-a716-446655440001"  // ✅ Required (UUID string)
```

**Request Body:** None

**Response (200 OK):**
```json
{
  "message": "Document deleted successfully"
}
```

**Error Responses:**
- **401 Unauthorized:** Missing or invalid JWT token
- **404 Not Found:** Document not found or access denied
- **500 Internal Server Error:** Deletion failed

---

## Quiz Endpoints

### 14. Create Quiz
**Endpoint:** `POST /quiz/add`

**Description:** Create a new quiz with optional questions and answers.

**Request Headers:**
```json
{
  "Authorization": "Bearer <JWT_TOKEN>",
  "Content-Type": "application/json"
}
```

**Request Body:**
```json
{
  "documentID": "660e8400-e29b-41d4-a716-446655440001",  // ✅ Required (UUID string)
  "name": "Quiz Title",              // ✅ Required (string)
  "questions": [                     // ❌ Optional (array)
    {
      "text": "What is 2 + 2?",      // ✅ Required if questions provided (string)
      "answers": [                   // ❌ Optional (array)
        {
          "text": "4",               // ✅ Required if answers provided (string)
          "isCorrect": true          // ❌ Optional (boolean, defaults to false)
        },
        {
          "text": "5",
          "isCorrect": false
        }
      ]
    }
  ]
}
```

**Response (201 Created):**
```json
{
  "message": "Quiz created successfully",
  "quiz": {
    "quiz_id": "770e8400-e29b-41d4-a716-446655440002",
    "document_id": "660e8400-e29b-41d4-a716-446655440001",
    "name": "Quiz Title",
    "created_at": "2024-01-15T10:30:00Z",
    "questions": [
      {
        "question_id": "880e8400-e29b-41d4-a716-446655440003",
        "quiz_id": "770e8400-e29b-41d4-a716-446655440002",
        "text": "What is 2 + 2?",
        "created_at": "2024-01-15T10:30:00Z",
        "answers": [
          {
            "answer_id": "990e8400-e29b-41d4-a716-446655440004",
            "question_id": "880e8400-e29b-41d4-a716-446655440003",
            "text": "4",
            "is_correct": true,
            "user_selected": false,
            "created_at": "2024-01-15T10:30:00Z"
          },
          {
            "answer_id": "aa0e8400-e29b-41d4-a716-446655440005",
            "question_id": "880e8400-e29b-41d4-a716-446655440003",
            "text": "5",
            "is_correct": false,
            "user_selected": false,
            "created_at": "2024-01-15T10:30:00Z"
          }
        ]
      }
    ]
  }
}
```

**Error Responses:**
- **400 Bad Request:** Missing documentID or name
- **401 Unauthorized:** Missing or invalid JWT token
- **403 Forbidden:** Document not found or user doesn't have access

---

### 15. Get All Quizzes by User
**Endpoint:** `GET /quiz/all`

**Description:** Retrieve all quizzes belonging to the authenticated user across all documents.

**Request Headers:**
```json
{
  "Authorization": "Bearer <JWT_TOKEN>"
}
```

**Request Body:** None

**Response (200 OK):**
```json
{
  "quizzes": [
    {
      "quiz_id": "770e8400-e29b-41d4-a716-446655440002",
      "document_id": "660e8400-e29b-41d4-a716-446655440001",
      "name": "Quiz Title",
      "created_at": "2024-01-15T10:30:00Z",
      "questions": [
        {
          "question_id": "880e8400-e29b-41d4-a716-446655440003",
          "quiz_id": "770e8400-e29b-41d4-a716-446655440002",
          "text": "What is 2 + 2?",
          "created_at": "2024-01-15T10:30:00Z",
          "userAnswer": "4",
          "answers": [
            {
              "answer_id": "990e8400-e29b-41d4-a716-446655440004",
              "question_id": "880e8400-e29b-41d4-a716-446655440003",
              "text": "4",
              "is_correct": true,
              "user_selected": true,
              "created_at": "2024-01-15T10:30:00Z"
            },
            {
              "answer_id": "aa0e8400-e29b-41d4-a716-446655440005",
              "question_id": "880e8400-e29b-41d4-a716-446655440003",
              "text": "5",
              "is_correct": false,
              "user_selected": false,
              "created_at": "2024-01-15T10:30:00Z"
            }
          ]
        }
      ]
    }
  ],
  "count": 1
}
```

**Error Responses:**
- **401 Unauthorized:** Missing or invalid JWT token

---

### 16. Get Quizzes by Document
**Endpoint:** `GET /quiz/document/:documentID`

**Description:** Retrieve all quizzes for a specific document.

**Request Headers:**
```json
{
  "Authorization": "Bearer <JWT_TOKEN>"
}
```

**URL Parameters:**
```
documentID: "660e8400-e29b-41d4-a716-446655440001"  // ✅ Required (UUID string)
```

**Request Body:** None

**Response (200 OK):**
```json
{
  "quizzes": [
    {
      "quiz_id": "770e8400-e29b-41d4-a716-446655440002",
      "document_id": "660e8400-e29b-41d4-a716-446655440001",
      "name": "Quiz Title",
      "created_at": "2024-01-15T10:30:00Z",
      "questions": [
        {
          "question_id": "880e8400-e29b-41d4-a716-446655440003",
          "quiz_id": "770e8400-e29b-41d4-a716-446655440002",
          "text": "What is 2 + 2?",
          "created_at": "2024-01-15T10:30:00Z",
          "answers": [
            {
              "answer_id": "990e8400-e29b-41d4-a716-446655440004",
              "question_id": "880e8400-e29b-41d4-a716-446655440003",
              "text": "4",
              "is_correct": true,
              "user_selected": false,
              "created_at": "2024-01-15T10:30:00Z"
            }
          ]
        }
      ]
    }
  ]
}
```

**Error Responses:**
- **401 Unauthorized:** Missing or invalid JWT token
- **403 Forbidden:** Document not found or access denied
- **404 Not Found:** Quizzes not found

---

### 17. Get Specific Quiz
**Endpoint:** `GET /quiz/:quizID`

**Description:** Retrieve a specific quiz by ID with all its questions and answers including user responses.

**Request Headers:**
```json
{
  "Authorization": "Bearer <JWT_TOKEN>"
}
```

**URL Parameters:**
```
quizID: "770e8400-e29b-41d4-a716-446655440002"  // ✅ Required (UUID string)
```

**Request Body:** None

**Response (200 OK):**
```json
{
  "quiz": {
    "quiz_id": "770e8400-e29b-41d4-a716-446655440002",
    "document_id": "660e8400-e29b-41d4-a716-446655440001",
    "name": "Quiz Title",
    "created_at": "2024-01-15T10:30:00Z",
    "questions": [
      {
        "question_id": "880e8400-e29b-41d4-a716-446655440003",
        "quiz_id": "770e8400-e29b-41d4-a716-446655440002",
        "text": "What is 2 + 2?",
        "created_at": "2024-01-15T10:30:00Z",
        "userAnswer": "4",
        "answers": [
          {
            "answer_id": "990e8400-e29b-41d4-a716-446655440004",
            "question_id": "880e8400-e29b-41d4-a716-446655440003",
            "text": "4",
            "is_correct": true,
            "user_selected": true,
            "created_at": "2024-01-15T10:30:00Z"
          },
          {
            "answer_id": "aa0e8400-e29b-41d4-a716-446655440005",
            "question_id": "880e8400-e29b-41d4-a716-446655440003",
            "text": "5",
            "is_correct": false,
            "user_selected": false,
            "created_at": "2024-01-15T10:30:00Z"
          }
        ]
      }
    ]
  }
}
```

**Error Responses:**
- **401 Unauthorized:** Missing or invalid JWT token
- **403 Forbidden:** Document not found or access denied
- **404 Not Found:** Quiz not found

---

### 18. Update Quiz
**Endpoint:** `PUT /quiz/:quizID`

**Description:** Update quiz name and/or questions and answers.

**Request Headers:**
```json
{
  "Authorization": "Bearer <JWT_TOKEN>",
  "Content-Type": "application/json"
}
```

**URL Parameters:**
```
quizID: "770e8400-e29b-41d4-a716-446655440002"      // ✅ Required (UUID string)
```

**Request Body:**
```json
{
  "name": "Updated Quiz Title",      // ✅ Required (string)
  "questions": [                     // ❌ Optional (array)
    {
      "question_id": "880e8400-e29b-41d4-a716-446655440003",  // ❌ Optional - if provided, updates existing question (UUID string)
      "text": "Updated question?",    // ❌ Optional if question_id provided, Required for new questions (string)
      "answers": [                   // ❌ Optional (array)
        {
          "answer_id": "990e8400-e29b-41d4-a716-446655440004",  // ❌ Optional - if provided, updates existing answer (UUID string)
          "text": "Updated answer",   // ❌ Optional if answer_id provided, Required for new answers (string)
          "is_correct": true         // ❌ Optional (boolean, defaults to false)
        },
        {
          "text": "New answer",
          "is_correct": false
        }
      ]
    },
    {
      "text": "Completely new question?"
    }
  ]
}
```

**Response (200 OK):**
```json
{
  "message": "Quiz updated successfully",
  "quiz": {
    "quiz_id": "770e8400-e29b-41d4-a716-446655440002",
    "document_id": "660e8400-e29b-41d4-a716-446655440001",
    "name": "Updated Quiz Title",
    "created_at": "2024-01-15T10:30:00Z",
    "questions": [
      {
        "question_id": "880e8400-e29b-41d4-a716-446655440003",
        "quiz_id": "770e8400-e29b-41d4-a716-446655440002",
        "text": "Updated question?",
        "created_at": "2024-01-15T10:30:00Z",
        "answers": [
          {
            "answer_id": "990e8400-e29b-41d4-a716-446655440004",
            "question_id": "880e8400-e29b-41d4-a716-446655440003",
            "text": "Updated answer",
            "is_correct": true,
            "user_selected": false,
            "created_at": "2024-01-15T10:30:00Z"
          }
        ]
      }
    ]
  }
}
```

**Error Responses:**
- **400 Bad Request:** Missing quiz name
- **401 Unauthorized:** Missing or invalid JWT token
- **403 Forbidden:** Document not found or access denied
- **404 Not Found:** Quiz not found

---

### 19. Delete Quiz
**Endpoint:** `DELETE /quiz/:quizID`

**Description:** Delete a quiz and all associated questions and answers.

**Request Headers:**
```json
{
  "Authorization": "Bearer <JWT_TOKEN>"
}
```

**URL Parameters:**
```
quizID: "770e8400-e29b-41d4-a716-446655440002"      // ✅ Required (UUID string)
```

**Request Body:** None

**Response (200 OK):**
```json
{
  "message": "Quiz deleted successfully"
}
```

**Error Responses:**
- **401 Unauthorized:** Missing or invalid JWT token
- **403 Forbidden:** Document not found or access denied
- **404 Not Found:** Quiz not found

---

## Authentication Notes

- All endpoints except `/auth/signup` and `/auth/login` require a valid JWT token in the `Authorization` header
- Format: `Authorization: Bearer <JWT_TOKEN>`
- JWT tokens expire after 7 days
- Include the token exactly as received from the login/signup response

---

## Common Error Responses

### 401 Unauthorized
```json
{
  "message": "Unauthorized"
}
```
**Cause:** Missing or invalid JWT token

### 403 Forbidden
```json
{
  "message": "Document not found or access denied"
}
```
**Cause:** User doesn't have permission to access the resource

### 404 Not Found
```json
{
  "message": "Resource not found"
}
```
**Cause:** Requested resource doesn't exist

### 500 Internal Server Error
```json
{
  "message": "Internal server error"
}
```
**Cause:** Server-side error during processing

---

## Request/Response Summary Table

| Endpoint | Method | Auth Required | Body Type | Description |
|----------|--------|---------------|-----------|-------------|
| `/auth/signup` | POST | No | JSON | Create account |
| `/auth/login` | POST | No | JSON | Login user |
| `/user/` | GET | Yes | None | Get profile |
| `/user/update` | PUT | Yes | Form Data | Update profile |
| `/user/profile-picture` | GET | Yes | None | Download picture |
| `/user/delete` | DELETE | Yes | None | Delete account |
| `/user/settings/darkmode` | PUT | Yes | JSON | Toggle dark mode |
| `/user/settings/language` | PUT | Yes | JSON | Change language |
| `/document/add` | POST | Yes | Form Data | Upload document |
| `/document/allDocsMetaData` | GET | Yes | None | List documents |
| `/document/:documentID` | GET | Yes | None | Download document |
| `/document/edit/:documentID` | PUT | Yes | Form Data | Update document |
| `/document/delete/:documentID` | DELETE | Yes | None | Delete document |
| `/quiz/add` | POST | Yes | JSON | Create quiz |
| `/quiz/all` | GET | Yes | None | Get all user quizzes |
| `/quiz/document/:documentID` | GET | Yes | None | Get quizzes by document |
| `/quiz/:quizID` | GET | Yes | None | Get specific quiz |
| `/quiz/:quizID` | PUT | Yes | JSON | Update quiz |
| `/quiz/:quizID` | DELETE | Yes | None | Delete quiz |

---

**Last Updated:** January 9, 2026  
**API Version:** 1.0