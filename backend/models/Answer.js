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
    const insertData = {
      question_id: questionID,
      text: answerData.text,
      is_correct: answerData.isCorrect || false,
    };

    // Add user_selected if provided
    if (answerData.userSelected !== undefined) {
      insertData.user_selected = answerData.userSelected;
    }

    const { data, error } = await supabase
      .from("Answer")
      .insert(insertData)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  static async update(answer_id, updateData) {
    const updatePayload = {};
    if (updateData.text !== undefined) updatePayload.text = updateData.text;
    if (updateData.isCorrect !== undefined) updatePayload.is_correct = updateData.isCorrect;
    if (updateData.userSelected !== undefined) updatePayload.user_selected = updateData.userSelected;

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