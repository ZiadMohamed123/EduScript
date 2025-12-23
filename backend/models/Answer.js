import { supabase } from "../config/supabase.js";

export class Answer {
  static async findById(answerID) {
    const { data, error } = await supabase
      .from("Answer")
      .select("*")
      .eq("answer_id", answerID)
      .single();

    if (error) throw error;
    return data;
  }

  static async findByQuestionId(questionID) {
    const { data, error } = await supabase
      .from("Answer")
      .select("*")
      .eq("question_id", questionID);

    if (error) throw error;
    return data;
  }

  static async create(questionID, answerData) {
    const { data, error } = await supabase
      .from("Answer")
      .insert({
        question_id: questionID,
        text: answerData.text,
        is_correct: answerData.isCorrect || false,
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  static async update(answer_id, updateData) {
    const updatePayload = {};
    if (updateData.text !== undefined) updatePayload.text = updateData.text;
    if (updateData.isCorrect !== undefined) updatePayload.is_correct = updateData.isCorrect;

    const { data, error } = await supabase
      .from("Answer")
      .update(updatePayload)
      .eq("answer_id", answer_id)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  static async delete(answer_id) {
    const { error } = await supabase
      .from("Answer")
      .delete()
      .eq("answer_id", answer_id);

    if (error) throw error;
    return true;
  }
}
