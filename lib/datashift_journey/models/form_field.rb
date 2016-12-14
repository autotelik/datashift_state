module DatashiftJourney
  module Models

    # This stores a single Field in a Form, where a field is generally a form
    # element that collects some kind of data
    #
    class FormField < ActiveRecord::Base

      self.table_name = 'dsj_form_fields'

      belongs_to :form

      has_many :data_nodes, class_name: "CollectorDataNode", foreign_key: :form_field_id, dependent: :destroy

      scope :for_form_and_field,   ->(form_name, field_name) {
        form = Form.where("form_name = ?", form_name).first
        return nil unless form
        form.form_fields.where("field = ?", field_name).first
      }

    end
  end
end

