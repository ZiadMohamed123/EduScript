import { supabase } from "../config/supabase.js";

export class Quiz {
  static async findById(quizID) {
    const { data, error } = await supabase
      .from("Quiz")
      .select("*")
      .eq("QuizID", quizID)
      .single();

    if (error) throw error;
    return data;
  }

  static async findByDocumentId(documentID) {
    const { data, error } = await supabase
      .from("Quiz")
      .select("*")
      .eq("documentID", documentID)
      .order("DateCreated", { ascending: false });

    if (error) throw error;
    return data;
  }

  static async create(documentID, quizData) {
    const { data, error } = await supabase
      .from("Quiz")
      .insert({
        documentID,
        Name: quizData.name,
        DateCreated: new Date().toISOString(),
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  static async update(quizID, updateData) {
    const updatePayload = {};
    if (updateData.name !== undefined) updatePayload.Name = updateData.name;

    const { data, error } = await supabase
      .from("Quiz")
      .update(updatePayload)
      .eq("QuizID", quizID)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  static async delete(quizID) {
    const { error } = await supabase
      .from("Quiz")
      .delete()
      .eq("QuizID", quizID);

    if (error) throw error;
    return true;
  }
}
