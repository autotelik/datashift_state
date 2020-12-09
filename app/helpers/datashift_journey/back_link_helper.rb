module DatashiftJourney
  module BackLinkHelper
    # Helper to create a standard Back link.
    # Containing apps are expected to provide their home page in a DSC config initializer
    # for DatashiftJourney.back_to_start_url
    def back_to_start_link(journey_plan = nil)
      DatashiftJourney::BackLink.new(request, engine_routes: datashift_journey, journey_plan: journey_plan).tag
    end
  end
end
