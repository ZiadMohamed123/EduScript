import { supabase } from "../config/supabase.js";
import fs from "fs";
import path from "path";
import { documentsUploadDir } from "../config/multer.js";

export class Document {
  static async findById(documentID) {
    const { data, error } = await supabase
      .from("Document")
      .select("*")
      .eq("documentID", documentID)
      .single();

    if (error) throw error;
    return data;
  }

  static async doesDocumentBelongToUser(documentID, userID) {
    const { data, error } = await supabase
      .from("Document")
      .select("*")
      .eq("documentID", documentID)
      .eq("userID", userID)
      .single();

    return error ? false : true;
  }

  static async findByUserId(userID) {
    const { data, error } = await supabase
      .from("Document")
      .select("documentID, name, noOfPages, uploadDate, fileName, Summary")
      .eq("userID", userID)
      .order("uploadDate", { ascending: false });

    if (error) throw error;
    return data;
  }

  static async create(userID, documentData) {
    const { data, error } = await supabase
      .from("Document")
      .insert({
        userID,
        name: documentData.name,
        noOfPages: documentData.noOfPages || 0,
        uploadDate: new Date().toISOString(),
        fileName: documentData.fileName,
        extractedText: documentData.extractedText || "",
        Summary: documentData.summary || "",
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  static async replaceDocumentInFile(documentID, newDocument) {
    try {
      const oldDocumentData = await this.findById(documentID);
      fs.unlinkSync(path.join(documentsUploadDir, oldDocumentData.fileName));
      return newDocument.filename;
    } catch (error) {
      const filePath = path.join(documentsUploadDir, newDocument.filename);
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
      }
      throw error;
    }
  }
  static async update(documentID, newDocument, updateData) {
    const updatePayload = {};
    if (newDocument)
      updatePayload.fileName = await this.replaceDocumentInFile(
        documentID,
        newDocument
      );
    if (updateData.name !== undefined) updatePayload.name = updateData.name;
    if (updateData.noOfPages !== undefined)
      updatePayload.noOfPages = updateData.noOfPages;
    if (updateData.extractedText !== undefined)
      updatePayload.extractedText = updateData.extractedText;
    if (updateData.summary !== undefined)
      updatePayload.Summary = updateData.summary;

    const { data, error } = await supabase
      .from("Document")
      .update(updatePayload)
      .eq("documentID", documentID)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  static async delete(documentID) {
    try {
      fs.unlinkSync(
        path.join(
          documentsUploadDir,
          (await this.findById(documentID)).fileName
        )
      );

      const { error } = await supabase
        .from("Document")
        .delete()
        .eq("documentID", documentID);

      if (error) throw error;
    } catch (error) {
      throw error;
    }
  }
}
