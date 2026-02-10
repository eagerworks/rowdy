Rowdy::Engine.routes.draw do
  resources :uploads, only: [:create, :show] do
    member do
      get :download
    end
  end
end
