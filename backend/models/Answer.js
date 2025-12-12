import { supabase } from "../config/supabase.js";

export class Answer {
  static async findById(answerID) {
    const { data, error } = await supabase
      .from("Answer")
      .select("*")
      .eq("AnswerID", answerID)
      .single();

    if (error) throw error;
    return data;
  }

  static async findByQuestionId(questionID) {
    const { data, error } = await supabase
      .from("Answer")
      .select("*")
      .eq("QuestionID", questionID);

    if (error) throw error;
    return data;
  }

  static async create(questionID, answerData) {
    const { data, error } = await supabase
      .from("Answer")
      .insert({
        QuestionID: questionID,
        Text: answerData.text,
        isCorrect: answerData.isCorrect || false,
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  static async update(answerID, updateData) {
    const updatePayload = {};
    if (updateData.text !== undefined) updatePayload.Text = updateData.text;
    if (updateData.isCorrect !== undefined) updatePayload.isCorrect = updateData.isCorrect;

    const { data, error } = await supabase
      .from("Answer")
      .update(updatePayload)
      .eq("AnswerID", answerID)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  static async delete(answerID) {
    const { error } = await supabase
      .from("Answer")
      .delete()
      .eq("AnswerID", answerID);

    if (error) throw error;
    return true;
  }
}
