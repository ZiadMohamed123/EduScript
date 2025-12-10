import express from "express";
import {
  addDocument,
  deleteDocument,
  getAllDocumentsMetadataByUserID,
  getDocumentFileByID,
  updateDocument,
} from "../services/document.js";

const router = express.Router();

// Endpoints
router.post("/add", addDocument);
router.put("/edit/:documentID", updateDocument);
router.delete("/delete/:documentID", deleteDocument);
router.get("/metadata", getAllDocumentsMetadataByUserID);
router.get("/:documentID", getDocumentFileByID);

export default router;
