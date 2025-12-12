import { supabase } from "../config/supabase.js";

export class Question {
  static async findById(questionID) {
    const { data, error } = await supabase
      .from("Question")
      .select("*")
      .eq("QuestionID", questionID)
      .single();

    if (error) throw error;
    return data;
  }

  static async findByQuizId(quizID) {
    const { data, error } = await supabase
      .from("Question")
      .select("*")
      .eq("QuizID", quizID);

    if (error) throw error;
    return data;
  }

  static async create(quizID, questionData) {
    const { data, error } = await supabase
      .from("Question")
      .insert({
        QuizID: quizID,
        Text: questionData.text,
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  static async update(questionID, updateData) {
    const updatePayload = {};
    if (updateData.text !== undefined) updatePayload.Text = updateData.text;

    const { data, error } = await supabase
      .from("Question")
      .update(updatePayload)
      .eq("QuestionID", questionID)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  static async delete(questionID) {
    const { error } = await supabase
      .from("Question")
      .delete()
      .eq("QuestionID", questionID);

    if (error) throw error;
    return true;
  }
}
