module DatashiftJourney
  module ApplicationHelper

    def render_if_exists(state, *args)
      lookup_context.prefixes.prepend DatashiftJourney::Configuration.call.partial_location

      Rails.logger.debug("DSJ search path(s) [#{lookup_context.prefixes.inspect}]")

      if lookup_context.exists?(state, lookup_context.prefixes, true)
        render(state, *args)
      elsif DatashiftJourney.using_collector?
        Rails.logger.debug("DSJ - Using generic Collector viws, no partial found for state #{state}")
        render('datashift_journey/collector/generic_form', *args)
      end
    end

    # Returns true if '_state' partial exists in configured location (Configuration.partial_location)

    def journey_plan_partial?(state)
      return true if lookup_context.exists?(state, [DatashiftJourney::Configuration.call.partial_location], true)

      Rails.logger.warn("DSJ - No partial found for [#{state}] in path(s) [#{lookup_context.prefixes.inspect}]")

      false
    end

    # helper to return the location of a partial for a particular state
    def journey_plan_partial_location(state)
      Rails.logger.debug("DatashiftJourney RENDER #{DatashiftJourney::Configuration.call.partial_location}/#{state}}")
      File.join(DatashiftJourney::Configuration.call.partial_location.to_s, state)
    end

    def submit_button_text(_form)
      t('global.journey_plan.continue')
    end

    # This helper  adds a form-group DIV around form elements,
    # and takes the actual form fields as a content block.
    #
    # Some coupling with app/views/shared/_errors.html.erb which displays
    # the actual validation errors and links between error display and the
    # associated form-group defined here
    #
    # Example Usage :
    # <%= form_group_and_validation(@journey_plan, :base) do %>
    #   <%= form.radio_button "blah", "new", checked: false, class: "radio" %>
    #   <%= form.radio_button "blah", "renew", checked: false, class: "radio" %>
    # <% end %>
    #
    def form_group_and_validation(model, attribute, &block)
      content = block_given? ? capture(&block) : ''

      options = { id: error_link_id(attribute), role: 'group' }

      if model && model.errors[attribute].any?

        content = content_tag(:span, model.errors[attribute].first.to_s.html_safe,
                              class: 'error-message') + content

        content_tag(:div, content, options.merge(class: 'form-group error'))

      else
        content_tag(:div, content, options.merge(class: 'form-group'))
      end
    end

    def error_link_id(attribute)
      # with nested attributes can get full path e.g applicant_contact.full_name
      # we only want the last field
      field = attribute.to_s.split(/\./).last
      "form_group_#{field}"
    end

    def all_errors(record)
      record.class.reflect_on_all_associations.each do |a|
        assoc = @journey_plan.send(a.name)
        next unless assoc && assoc.respond_to?(:errors)
        assoc.errors.full_messages.each do |_message|
          "<li><a href='<%= message %>'></a></li>"
        end
      end
    end

    def validation_for(model, attribute)
      if model.errors[attribute].any?
        # Note: Calling raw() forces the characters to be un-escaped
        # and thus HTML elements can be defined here
        raw("<span class=\"error-text\">#{model.errors[attribute].first}</span>")
      else
        ''
      end
    end

    def friendly_date(date)
      formatted_date = date && l(date.to_date, format: :long)
      formatted_date || ''
    end

  end
end
