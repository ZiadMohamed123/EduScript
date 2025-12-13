import multer from "multer";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { dirname } from "path";

export const __dirname = dirname(fileURLToPath(import.meta.url));

export const documentsUploadDir = path.join(__dirname, "../uploads/documents/");
export const profilePicturesUploadDir = path.join(__dirname, "../uploads/profile_pictures/");

if (!fs.existsSync(documentsUploadDir)) {
  fs.mkdirSync(documentsUploadDir, { recursive: true });
}

if (!fs.existsSync(profilePicturesUploadDir)) {
  fs.mkdirSync(profilePicturesUploadDir, { recursive: true });
}

// File filter for documents (PDF, DOCX, DOC, TXT)
const documentFileFilter = (req, file, cb) => {
  const allowedMimes = [
    "application/pdf",
    "application/msword",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "text/plain",
  ];

  if (allowedMimes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error("Invalid document type. Allowed: PDF, DOCX, DOC, TXT"), false);
  }
};

// File filter for profile pictures (JPEG, PNG, WebP)
const imageFileFilter = (req, file, cb) => {
  const allowedMimes = ["image/jpeg", "image/png", "image/webp"];

  if (allowedMimes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error("Invalid image type. Allowed: JPEG, PNG, WebP"), false);
  }
};

const documentsStorage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, documentsUploadDir);
  },
  filename: function (req, file, cb) {
    cb(null, Date.now() + "-" + file.originalname);
  },
});

export const documentsUpload = multer({
  storage: documentsStorage,
  fileFilter: documentFileFilter,
  limits: { fileSize: 50 * 1024 * 1024 }, // 50MB max
});

const profilePicturesStorage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, profilePicturesUploadDir);
  },
  filename: function (req, file, cb) {
    cb(null, Date.now() + "-" + file.originalname);
  },
});

export const profilePicturesUpload = multer({
  storage: profilePicturesStorage,
  fileFilter: imageFileFilter,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB max
});