Rowdy::Engine.routes.draw do
  resources :uploads, only: [:create, :show]
end
