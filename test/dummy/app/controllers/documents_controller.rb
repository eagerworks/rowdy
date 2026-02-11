class DocumentsController < ApplicationController
  def new
    @uploads = Rowdy::Upload.order(created_at: :desc).limit(20)
  end

  def index
    @uploads = Rowdy::Upload.order(created_at: :desc)
  end
end
