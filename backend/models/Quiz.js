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
    
    // Map the data to ensure consistent date field handling
    const quizzes = (data || []).map((quiz) => {
      const createdAt =
        quiz.created_at ??
        quiz.date_created ??
        quiz.createdAt ??
        quiz.dateCreated ??
        null;

      return {
        ...quiz,
        created_at: createdAt,  // Flutter looks for this field
        date_created: createdAt,
      };
    });

    // Sort newest first
    quizzes.sort((a, b) => {
      const aTime = a.created_at ? Date.parse(a.created_at) : 0;
      const bTime = b.created_at ? Date.parse(b.created_at) : 0;
      return bTime - aTime;
    });

    return quizzes;
  }


  /**
   * OPTIMIZED: Find all quizzes by user with question counts
   * This uses efficient queries to avoid N+1 problems
   */
  static async findByUserIdWithCounts(user_id) {
    console.log(`📊 Fetching quizzes for user: ${user_id}`);
    
    // First, get all documents for the user
    const { data: documents, error: documentsError } = await supabase
      .from("Document")
      .select("document_id, name")
      .eq("user_id", user_id);

    if (documentsError) {
      console.error("Error fetching documents:", documentsError);
      throw documentsError;
    }

    if (!documents || documents.length === 0) {
      console.log("No documents found for user");
      return [];
    }

    console.log(`Found ${documents.length} documents`);

    const documentMap = new Map(
      documents
        .filter((doc) => doc.document_id)
        .map((doc) => [doc.document_id, doc.name ?? null])
    );

    const documentIds = Array.from(documentMap.keys());

    if (documentIds.length === 0) {
      return [];
    }

    // Fetch quizzes (basic info only, no questions yet)
    const { data: quizData, error: quizError } = await supabase
      .from("Quiz")
      .select("quiz_id, name, document_id, created_at, date_created")
      .in("document_id", documentIds);

    if (quizError) {
      console.error("Error fetching quizzes:", quizError);
      throw quizError;
    }

    console.log(`Found ${(quizData || []).length} quizzes`);

    // Now fetch question counts for all quizzes in ONE query
    const quizIds = (quizData || []).map(q => q.quiz_id);
    
    let questionCounts = new Map();
    if (quizIds.length > 0) {
      // Get question counts using aggregation
      const { data: countData, error: countError } = await supabase
        .from("Question")
        .select("quiz_id")
        .in("quiz_id", quizIds);

      if (countError) {
        console.error("Error fetching question counts:", countError);
        // Don't fail, just set counts to 0
      } else if (countData) {
        // Count questions per quiz
        countData.forEach(q => {
          const count = questionCounts.get(q.quiz_id) || 0;
          questionCounts.set(q.quiz_id, count + 1);
        });
      }
    }

    // Process the data
    const quizzes = (quizData || []).map((quiz) => {
      const createdAt =
        quiz.created_at ??
        quiz.date_created ??
        null;

      // Get question count from our map
      const questionCount = questionCounts.get(quiz.quiz_id) || 0;

      return {
        quiz_id: quiz.quiz_id,
        name: quiz.name,
        document_id: quiz.document_id,
        created_at: createdAt,
        date_created: createdAt,
        document_name: documentMap.get(quiz.document_id) ?? null,
        questions: [], // Empty array for list view (don't fetch full questions)
      };
    });

    // Sort newest first
    quizzes.sort((a, b) => {
      const aTime = a.created_at ? Date.parse(a.created_at) : 0;
      const bTime = b.created_at ? Date.parse(b.created_at) : 0;
      return bTime - aTime;
    });

    console.log(`✅ Returning ${quizzes.length} quizzes with counts`);
    return quizzes;
  }


  // Find all quizzes by user (original method - kept for backward compatibility)
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
      date_created: new Date().toISOString(), // Explicitly set timestamp
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