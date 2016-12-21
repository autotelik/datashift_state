# These collector are in lib since usage of them is Optional

module DatashiftJourney
  module Collector
    class Collector < ActiveRecord::Base

      self.table_name = 'dsj_collectors'

      include DatashiftJourney::ReferenceGenerator.new(prefix: 'C')

      has_many :data_nodes, class_name: 'CollectorDataNode', foreign_key: :collector_id, dependent: :destroy

      has_many :form_fields, through: :data_nodes, source: :form_field

      has_many :page_states, through: :form_fields

      def node_for_form_and_field(form_name, field_name)
        form_field = FormField.for_form_and_field(form_name, field_name)
        return nil unless form_field
        data_nodes.where(form_field: form_field).first
      end

      def node_for_form_field(form_field)
        data_nodes.find(form_field).first
      end

#      Could not find the source association(s) "form" or :forms in
# model DatashiftJourney::Collector::FormField. Try 'has_many :forms, :through => :form_fields, :source => <name>'. Is it one of page_state, data_nodes, snippets, or field_snippets?

      def nodes_for_form(form_name)
        form = page_states.where(form_name: form_name).first
        return [] unless form
        form.data_nodes.all.to_a
      end

    end
  end
end
