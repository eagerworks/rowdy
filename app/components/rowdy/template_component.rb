module Rowdy
  class TemplateComponent < ViewComponent::Base
    def initialize(schema:)
      @schema = schema
      puts "schema: #{@schema.inspect}"
      @uploads = Upload.where(schema_name: @schema.schema_name).order(created_at: :desc)
    end

    def steps_frame_id
      "rowdy-template-steps-#{@schema.schema_name}"
    end
  end
end
