class Over55Question1Form < BaseForm

  def self.factory(journey)

    # Auto generated by DatashiftJourney - check the Model this Form is managing, something like
    # state = Over55Question1.new
    # new(state, journey)

    # For example if this page concerned with collecting data for an Organisation model  might expect :

    # organisation = journey.organisation
    # new(organisation, journey)

    # If you have no separate model, or are using DatashiftJourney::Collector as your journey class can just use
     new(journey)
  end

  def params_key
    :over55_question1
  end
end
