Rowdy::Engine.routes.draw do
  resources :uploads, only: [ :create ]

  scope :chunked_uploads do
    post   "/",                to: "chunked_uploads#initiate",       as: :chunked_uploads
    get    "/:token",          to: "chunked_uploads#status",         as: :chunked_upload_status
    put    "/:token/:index",   to: "chunked_uploads#receive_chunk",  as: :chunked_upload_chunk
    post   "/:token/complete", to: "chunked_uploads#complete",       as: :chunked_upload_complete
  end

  resources :imports, only: [ :create, :show ] do
    resource :mapping, only: [ :show, :update ], controller: "imports/mappings"
    resource :validation, only: [ :show, :create ], controller: "imports/validations"
    member do
      patch  :correct_errors
      patch  :replace_all
      get    :error_report
      get    :valid_rows_report
    end
  end

  resources :schema_definitions, only: %i[index show create update destroy]
  resources :schemas, only: [ :show ], param: :schema_name
end
