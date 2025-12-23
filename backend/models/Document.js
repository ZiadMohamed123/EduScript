import { supabase } from "../config/supabase.js";
import fs from "fs";
import path from "path";
import { documentsUploadDir } from "../config/multer.js";

export class Document {
  static async findById(document_id) {
    const { data, error } = await supabase
      .from("Document")
      .select("*")
      .eq("document_id", document_id)
      .single();

    if (error) throw error;
    return data;
  }

  static async doesDocumentBelongToUser(document_id, user_id) {
    const { data, error } = await supabase
      .from("Document")
      .select("*")
      .eq("document_id", document_id)
      .eq("user_id", user_id)
      .single();

    return error ? false : true;
  }

  static async findByUserId(user_id) {
    const { data, error } = await supabase
      .from("Document")
      .select("document_id, name, no_of_pages, upload_date, file_name, summary, extracted_text")
      .eq("user_id", user_id)
      .order("upload_date", { ascending: false });

    if (error) throw error;
    return data;
  }

  static async create(user_id, documentData) {
    const { data, error } = await supabase
      .from("Document")
      .insert({
        user_id: user_id,
        name: documentData.name,
        no_of_pages: documentData.noOfPages || 0,
        upload_date: new Date().toISOString(),
        file_name: documentData.fileName,
        extracted_text: documentData.extractedText || "",
        summary: documentData.summary || "",
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  static async replaceDocumentInFile(document_id, newDocument) {
    try {
      const oldDocumentData = await this.findById(document_id);
      fs.unlinkSync(path.join(documentsUploadDir, oldDocumentData.file_name));
      return newDocument.filename;
    } catch (error) {
      const filePath = path.join(documentsUploadDir, newDocument.file_name);
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
      }
      throw error;
    }
  }
  static async update(document_id, newDocument, updateData) {
    const updatePayload = {};
    if (newDocument)
      updatePayload.file_name = await this.replaceDocumentInFile(
        document_id,
        newDocument
      );
    if (updateData.name !== undefined) updatePayload.name = updateData.name;
    if (updateData.noOfPages !== undefined)
      updatePayload.no_of_pages = updateData.noOfPages;
    if (updateData.extractedText !== undefined)
      updatePayload.extracted_text = updateData.extractedText;
    if (updateData.summary !== undefined)
      updatePayload.summary = updateData.summary;

    const { data, error } = await supabase
      .from("Document")
      .update(updatePayload)
      .eq("document_id", document_id)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  static async delete(document_id) {
    try {
      // Get document info first
      const document = await this.findById(document_id);
      
      // Try to delete the file, but don't fail if file doesn't exist
      if (document && document.file_name) {
          const filePath = path.join(documentsUploadDir, document.file_name);
          if (fs.existsSync(filePath)) {
            fs.unlinkSync(filePath);
          }
      }

      const { error } = await supabase
        .from("Document")
        .delete()
        .eq("document_id", document_id);

      if (error) throw error;
    } catch (error) {
      throw error;
    }
  }
}
