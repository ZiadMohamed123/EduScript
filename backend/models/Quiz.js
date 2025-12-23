// models/Quiz.js
import { supabase } from "../config/supabase.js";

export class Quiz {
  static async findById(quiz_id) {
    const { data, error } = await supabase
      .from("Quiz")
      .select("*")
      .eq("quiz_id", quiz_id)
      .single();

    if (error) throw error;
    return data;
  }

  static async findByDocumentId(document_id) {
    const { data, error } = await supabase
      .from("Quiz")
      .select("*")
      .eq("document_id", document_id);

    if (error) throw error;
    return data;
  }

  // Find all quizzes by user
  static async findByUserId(user_id) {
    const { data: documents, error: documentsError } = await supabase
      .from("Document")
      .select("document_id, name")
      .eq("user_id", user_id);

    if (documentsError) throw documentsError;

    if (!documents || documents.length === 0) {
      return [];
    }

    const documentMap = new Map(
      documents
        .filter((doc) => doc.document_id)
        .map((doc) => [doc.document_id, doc.name ?? null])
    );

    const documentIds = Array.from(documentMap.keys());

    if (documentIds.length === 0) {
      return [];
    }

    const { data, error } = await supabase
      .from("Quiz")
      .select("*")
      .in("document_id", documentIds);

    if (error) throw error;

    const quizzes = (data || []).map((quiz) => {
      const createdAt =
        quiz.created_at ??
        quiz.date_created ??
        quiz.createdAt ??
        quiz.dateCreated ??
        null;

      return {
        quiz_id: quiz.quiz_id,
        name: quiz.name,
        document_id: quiz.document_id,
        created_at: createdAt,
        date_created: createdAt,
        document_name: documentMap.get(quiz.document_id) ?? null,
      };
    });

    // Sort newest first in case the database does not guarantee order
    quizzes.sort((a, b) => {
      const aTime = a.created_at ? Date.parse(a.created_at) : 0;
      const bTime = b.created_at ? Date.parse(b.created_at) : 0;
      return bTime - aTime;
    });

    return quizzes;
  }

  // Updated to accept user_id parameter
  static async create(document_id, user_id, quizData) {
    const basePayload = {
      document_id,
      name: quizData.name,
    };

    const shouldIncludeUserId = user_id !== undefined && user_id !== null;

    const attemptInsert = async (payload) =>
      supabase.from("Quiz").insert(payload).select().single();

    let payload = basePayload;

    if (shouldIncludeUserId) {
      payload = { ...basePayload, user_id };
    }

    let { data, error } = await attemptInsert(payload);

    const isMissingUserIdColumn = (supabaseError) => {
      if (!supabaseError) return false;
      const combined = `${supabaseError.message ?? ""} ${supabaseError.details ?? ""}`.toLowerCase();
      return combined.includes("user_id");
    };

    if (error && shouldIncludeUserId && isMissingUserIdColumn(error)) {
      ({ data, error } = await attemptInsert(basePayload));
    }

    if (error) throw error;
    return data;
  }

  static async update(quiz_id, updateData) {
    const { data, error } = await supabase
      .from("Quiz")
      .update({
        name: updateData.name,
      })
      .eq("quiz_id", quiz_id)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  static async delete(quiz_id) {
    const { error } = await supabase
      .from("Quiz")
      .delete()
      .eq("quiz_id", quiz_id);

    if (error) throw error;
  }
}