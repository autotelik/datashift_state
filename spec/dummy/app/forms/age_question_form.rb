
class AgeQuestionForm < BaseForm

  def self.factory(journey)
    # Auto generated by DatashiftJourney - check this is really the Model this Form is managing
    model ||= AgeQuestion.new
    new(model, journey)
  end

  def params_key
    :age_question
  end
end

