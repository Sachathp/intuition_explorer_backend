Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # API routes
  namespace :api do
    namespace :v1 do
      resources :atoms, only: [:index, :show] do
        member do
          get 'history'
        end
      end
      
      get 'search', to: 'search#index'
      get 'trending', to: 'trending#index'
      
      # Routes pour synchroniser les données depuis la blockchain Intuition
      post 'sync', to: 'sync#create'
      get 'sync/status', to: 'sync#status'
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
