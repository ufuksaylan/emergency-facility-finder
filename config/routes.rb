Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :admin do
    post "/login", to: "authentication#login"
    get "/dashboard", to: "dashboard#index"
    post "/register", to: "users#create"
    resources :facilities, param: :osm_id
    resources :specialties, only: [ :index ]
    resources :complaints, only: [ :index, :show, :edit, :update, :destroy ]
    # Example: Route to get current admin user info
  end

  resources :facilities, only: [:index, :show] do
    # THIS LINE MAKES RAILS LISTEN AT /facilities/:facility_id/complaints
    resources :complaints, only: [:create]
  end

  resources :specialties, only: [ :index ]
  
  get "/route/v1/:profile/*osrm_path",
      to: "osrm_proxy#route",
      constraints: {
        profile: /driving|foot/,
        osrm_path: /.*/ # <--- ADD THIS CONSTRAINT
      },
      as: :osrm_proxy
  # Defines the root path route ("/")
  # root "posts#index"#
end
