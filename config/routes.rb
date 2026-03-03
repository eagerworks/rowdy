Rowdy::Engine.routes.draw do
  resources :uploads, only: [ :create ]

  scope :chunked_uploads do
    post   "/",                to: "chunked_uploads#initiate",       as: :chunked_uploads
    get    "/:token",          to: "chunked_uploads#status",         as: :chunked_upload_status
    put    "/:token/:index",   to: "chunked_uploads#receive_chunk",  as: :chunked_upload_chunk
    post   "/:token/complete", to: "chunked_uploads#complete",       as: :chunked_upload_complete
  end

  resources :imports, only: [ :create, :show ] do
    member do
      get    :mapping
      patch  :save_mapping
      post   :validate
      get    :validation
      patch  :correct_errors
      get    :error_report
    end
  end
end
