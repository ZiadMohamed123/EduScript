import { supabase } from '../config/supabase.js';

export const addDocument = async (req, res, next) => {
  try {
    const userID = req.user.userID;
    const { name, noOfPages, fileName, extractedText, summary } = req.body;

    // Validate required fields
    if (!name || !fileName) {
      return res.status(400).json({
        success: false,
        message: "Name and fileName are required",
      });
    }

    const { data: newDocument, error } = await supabase
      .from("Document")
      .insert({
        userID,
        name,
        noOfPages: noOfPages || 0,
        uploadDate: new Date().toISOString(),
        fileName,
        extractedText: extractedText || "",
        Summary: summary || "",
      })
      .select()
      .single();

    if (error) throw error;

    res.status(201).json({
      success: true,
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
    const { data: document, error: checkError } = await supabase
      .from("Document")
      .select("documentID")
      .eq("documentID", documentID)
      .eq("userID", userID)
      .single();

    if (checkError || !document) {
      return res.status(404).json({
        success: false,
        message: "Document not found or access denied",
      });
    }

    const updateData = {};
    if (name !== undefined) updateData.name = name;
    if (noOfPages !== undefined) updateData.noOfPages = noOfPages;
    if (extractedText !== undefined) updateData.extractedText = extractedText;
    if (summary !== undefined) updateData.Summary = summary;

    const { data: updatedDocument, error } = await supabase
      .from("Document")
      .update(updateData)
      .eq("documentID", documentID)
      .select()
      .single();

    if (error) throw error;

    res.json({
      success: true,
      message: "Document updated successfully",
      document: updatedDocument,
    });
  } catch (error) {
    next(error);
  }
};

export const deleteDocument = async (req, res, next) => {
  try {
    const userID = req.user.userID;
    const { documentID } = req.params;

    // Check if document belongs to user
    const { data: document, error: checkError } = await supabase
      .from('Document')
      .select('documentID')
      .eq('documentID', documentID)
      .eq('userID', userID)
      .single();

    if (checkError || !document) {
      return res.status(404).json({
        success: false,
        message: 'Document not found or access denied'
      });
    }

    const { error } = await supabase
      .from('Document')
      .delete()
      .eq('documentID', documentID);

    if (error) throw error;

    res.json({
      success: true,
      message: 'Document deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

export const getAllDocumentsMetadataByUserID = async (req, res, next) => {
  try {
    const userID = req.user.userID;

    const { data: documents, error } = await supabase
      .from('Document')
      .select('documentID, name, noOfPages, uploadDate, fileName, Summary')
      .eq('userID', userID)
      .order('uploadDate', { ascending: false });

    if (error) throw error;

    res.json({
      success: true,
      documents: documents || [],
      count: documents?.length || 0
    });
  } catch (error) {
    next(error);
  }
};

export const getDocumentFileByID = async (req, res, next) => {
  try {
    const userID = req.user.userID;
    const { documentID } = req.params;

    const { data: document, error } = await supabase
      .from('Document')
      .select('*')
      .eq('documentID', documentID)
      .eq('userID', userID)
      .single();

    if (error || !document) {
      return res.status(404).json({
        success: false,
        message: 'Document not found'
      });
    }

    res.json({
      success: true,
      document
    });
  } catch (error) {
    next(error);
  }
};