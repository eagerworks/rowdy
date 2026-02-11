Rails.application.routes.draw do
  mount Rowdy::Engine => "/rowdy"

  root "documents#new"
  resources :documents, only: [ :new, :index ]
end
