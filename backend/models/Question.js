import { supabase } from "../config/supabase.js";

export class Question {
  static async findById(question_id) {
    const { data, error } = await supabase
      .from("Question")
      .select("*")
      .eq("question_id", question_id)
      .single();

    if (error) throw error;
    return data;
  }

  static async findByQuizId(quiz_id) {
    const { data, error } = await supabase
      .from("Question")
      .select("*")
      .eq("quiz_id", quiz_id);

    if (error) throw error;
    return data;
  }

  static async create(quiz_id, questionData) {
    const { data, error } = await supabase
      .from("Question")
      .insert({
        quiz_id: quiz_id,
        text: questionData.text,
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  static async update(question_id, updateData) {
    const updatePayload = {};
    if (updateData.text !== undefined) updatePayload.text = updateData.text;

    const { data, error } = await supabase
      .from("Question")
      .update(updatePayload)
      .eq("question_id", question_id)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  static async delete(question_id) {
    const { error } = await supabase
      .from("Question")
      .delete()
      .eq("question_id", question_id);

    if (error) throw error;
    return true;
  }
}
