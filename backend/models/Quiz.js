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
      .eq("document_id", document_id)
      .order("date_created", { ascending: false });

    if (error) throw error;
    return data;
  }

  static async create(document_id, quizData) {
    const { data, error } = await supabase
      .from("Quiz")
      .insert({
        document_id,
        name: quizData.name,
        date_created: new Date().toISOString(),
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  static async update(quiz_id, updateData) {
    const updatePayload = {};
    if (updateData.name !== undefined) updatePayload.name = updateData.name;

    const { data, error } = await supabase
      .from("Quiz")
      .update(updatePayload)
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
    return true;
  }
}
