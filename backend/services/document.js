import { Document } from "../models/Document.js";
import path from "path";
import fs from "fs";
import { documentsUploadDir } from "../config/multer.js";

export const addDocument = async (req, res, next) => {
  try {
    const userID = req.user.userID;
    const { name, noOfPages, extractedText, summary } = req.body;

    // Validate required fields
    if (!name || !req.file) {
      return res.status(400).json({
        message: "Name and file are required",
      });
    }

    const newDocument = await Document.create(userID , {
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
    const userID = req.user.userID;
    const { documentID } = req.params;
    const { name, noOfPages, extractedText, summary } = req.body;

    // Check if document belongs to user
    if (!(await Document.doesDocumentBelongToUser(documentID, userID))) {
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
    const userID = req.user.userID;
    const { documentID } = req.params;

    // Check if document belongs to user
    if (!(await Document.doesDocumentBelongToUser(documentID, userID))) {
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
    const userID = req.user.userID;

    const documents = await Document.findByUserId(userID);

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
    const userID = req.user.userID;
    const { documentID } = req.params;

    if(!(await Document.doesDocumentBelongToUser(documentID, userID))) {
      return res.status(404).json({
        message: "Document not found or access denied",
      });
    }

    const document = await Document.findById(documentID);

    const filePath = path.join( documentsUploadDir , document.fileName);
    
    if (!fs.existsSync(filePath)) {
      return res.status(404).json({
        message: "Document file not found",
      });
    }

    res.sendFile(path.join(documentsUploadDir , document.fileName));
  } catch (error) {
    next(error);
  }
};