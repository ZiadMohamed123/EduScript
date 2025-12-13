import { Document } from "../models/Document.js";
import path from "path";
import fs from "fs";
import { documentsUploadDir } from "../config/multer.js";

export const addDocument = async (req, res, next) => {
  try {
    const user_id = req.user.user_id;
    const { name, noOfPages, extractedText, summary } = req.body;

    // Validate required fields
    if (!name || !req.file) {
      return res.status(400).json({
        message: "Name and file are required",
      });
    }

    const newDocument = await Document.create(user_id , {
      name,
      fileName: req.file.filename,
      noOfPages,
      extractedText,
      summary,
    });

    res.status(201).json({
      message: "Document added successfully",
      document: newDocument,
    });
  } catch (error) {
    next(error);
  }
};

export const updateDocument = async (req, res, next) => {
  try {
    const user_id = req.user.user_id;
    const { documentID } = req.params;
    const { name, noOfPages, extractedText, summary } = req.body;

    // Check if document belongs to user
    if (!(await Document.doesDocumentBelongToUser(documentID, user_id))) {
      return res.status(404).json({
        message: "Document not found or access denied",
      });
    };

    try {
      const updatedDocument = await Document.update(documentID, req.file, {
        name,
        noOfPages,
        extractedText,
        summary,
      });

      return res.json({
        message: "Document updated successfully",
        document: updatedDocument,
      });
    } catch (error) {
      return res.status(500).json({
        message: "Failed to update document",
      });
    }
  } catch (error) {
    next(error);
  }
};

export const deleteDocument = async (req, res, next) => {
  try {
    const user_id = req.user.user_id;
    const { documentID } = req.params;

    // Check if document belongs to user
    if (!(await Document.doesDocumentBelongToUser(documentID, user_id))) {
      return res.status(404).json({
        message: "Document not found or access denied",
      });
    };

    try {
      await Document.delete(documentID);
      
      return res.json({
        message: "Document deleted successfully",
      });
    } catch (error) {
      return res.status(500).json({
        message: "Failed to delete document",
      });
    }

  } catch (error) {
    next(error);
  }
};

export const getAllDocumentsMetadataByUserID = async (req, res, next) => {
  try {
    const user_id = req.user.user_id;

    const documents = await Document.findByUserId(user_id);

    res.json({
      documents: documents || [],
      count: documents?.length || 0,
    });
  } catch (error) {
    next(error);
  }
};

export const getDocumentFileByID = async (req, res, next) => {
  try {
    const user_id = req.user.user_id;
    const { documentID } = req.params;

    if(!(await Document.doesDocumentBelongToUser(documentID, user_id))) {
      return res.status(404).json({
        message: "Document not found or access denied",
      });
    }

    const document = await Document.findById(documentID);

    const filePath = path.join(documentsUploadDir , document.file_name);
    
    if (!fs.existsSync(filePath)) {
      return res.status(404).json({
        message: "Document file not found",
      });
    }

    res.sendFile(path.join(documentsUploadDir , document.file_name));
  } catch (error) {
    next(error);
  }
};