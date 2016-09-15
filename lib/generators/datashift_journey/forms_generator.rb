module DatashiftJourney

  class FormsGenerator < Rails::Generators::Base

    #class_option :journey_class, type: :string, required: true, banner: 'The ActiveRecord model to use to manage journey'

    desc "This generator creates an initializer and concern to setup and manage the journey Model"

    def create_form_per_state

      if(DatashiftJourney.journey_plan_class == DatashiftJourney::Collector)
        state_forms_for_collector
      else
        klass = begin
          DatashiftJourney.journey_plan_class
        rescue => e
          raise "Could not load the DatashiftJourney.journey_plan_class"
        end

        base_form_definition=<<-EOF
class BaseForm < DatashiftJourney::BaseForm

  def initialize(model, journey_plan = nil)
    super(model, journey_plan)
  end

end
        EOF

        create_file "app/forms/base_form.rb" do
          base_form_definition
        end

        klass.state_machine.states.map(&:name).each do |state|
          create_file "app/forms/#{state}_form.rb" do
            state_form_definition( state.to_s )
          end
        end
      end

    end

    private

    def state_forms_for_collector
      DatashiftJourney.journey_plan_class.state_machine.states.map(&:name).each do |state|
        create_file "app/forms/#{state}_form.rb" do
          state_forms_for_collector_definition( state.to_s )
        end
      end
    end

    def state_forms_for_collector_definition( state )

      collector_form_definition=<<-EOF
class  #{state.classify}Form < DatashiftJourney::BaseCollectorForm

  def params_key
    :#{state}
  end

  property :field_value
  validates :field_value, presence: true
end
      EOF

      collector_form_definition

    end

    def  state_form_definition( state )
      state_form_definition=<<-EOF
class #{state.classify}Form < BaseForm

  def self.factory(journey)

    # Auto generated by DatashiftJourney - check the Model this Form is managing, something like
    # state_model = #{state.classify}.new
    # new(state_model, journey)

    # For example if this page concerned with collecting data for an Organisation model  might expect :

    # organisation = journey.organisation
    # new(organisation, journey)

    # If you have no separate model just use
     new(journey)
  end

  def params_key
    :#{state}
  end
end

      EOF

      state_form_definition

    end


    def  state_form_definition( state )
      state_form_definition=<<-EOF
class #{state.classify}Form < BaseForm

  def self.factory(journey)

    # Auto generated by DatashiftJourney - check the Model this Form is managing, something like
    # state_model = #{state.classify}.new
    # new(state_model, journey)

    # For example if this page concerned with collecting data for an Organisation model  might expect :

    # organisation = journey.organisation
    # new(organisation, journey)

    # If you have no separate model just use
     new(journey)
  end

  def params_key
    :#{state}
  end
end

      EOF

      state_form_definition

    end

  end
end
