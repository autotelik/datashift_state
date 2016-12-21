require 'reform/form'

module DatashiftJourney
  class FormObjectFactory

    class << self
      def form_object_for(journey_plan)
        klass = form_class_for(journey_plan)

        unless klass
          raise(FormObjectError,
                "Failed to load form class #{form_name(journey_plan.state)} for state #{journey_plan.state}")
        end

        klass.factory(journey_plan)
      end

      def form_name(state)
        @form_name_mod ||= Configuration.call.forms_module_name

        "#{@form_name_mod}::#{state.to_s.camelize}Form"
      end

      private

      def null_form_for_state(journey_plan)
        return DatashiftJourney::NullForm if Configuration.call.use_null_form_when_no_form

        return DatashiftJourney:: NullForm if null_form_requirested?(journey_plan.state)

        nil
      end

      def null_form_requirested?(state)
        null_form_list.include?(state.to_s)
      end

      def null_form_list
        @null_form_list ||= Configuration.call.null_form_list.map!(&:to_s)
      end

      def form_class_for(journey_plan)
        form_name(journey_plan.state).constantize
      rescue => x

        null_form = null_form_for_state(journey_plan)

        unless null_form
          Rails.logger.debug(x.backtrace.first)
          Rails.logger.debug(x.inspect)
          Rails.logger.debug("No Form class found for state #{journey_plan.state} - #{x.message}")
          return nil
        end

        null_form
      end
    end

  end
end
