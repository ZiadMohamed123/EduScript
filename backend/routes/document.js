import express from "express";
import { documentsUpload } from "../config/multer.js";
import {
  addDocument,
  deleteDocument,
  getAllDocumentsMetadataByUserID,
  getDocumentFileByID,
  updateDocument,
} from "../services/document.js";

const router = express.Router();

// Endpoints
router.get("/allDocsMetaData", getAllDocumentsMetadataByUserID);
router.get("/:documentID", getDocumentFileByID);
router.post("/add", documentsUpload.single('document') ,addDocument);
router.put("/edit/:documentID", documentsUpload.single('newDocument'), updateDocument);
router.delete("/delete/:documentID", deleteDocument);

export default router;