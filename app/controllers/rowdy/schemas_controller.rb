module Rowdy
  class SchemasController < ApplicationController
    def show
      @schema = SchemaRegistry.find!(params[:schema_name])
      @uploads = Upload.where(schema_name: @schema.schema_name).order(created_at: :desc)
    end

    private

    helper_method :rowdy_back_path

    def rowdy_back_path
      request.referer || main_app.root_path
    rescue NoMethodError
      "/"
    end
  end
end
