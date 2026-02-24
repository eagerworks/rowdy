class DocumentsController < ApplicationController
  def new
  end

  def index
    @uploads = Rowdy::Upload.order(created_at: :desc)
  end
end
