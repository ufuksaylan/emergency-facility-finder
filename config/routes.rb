Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :admin do
    post "/login", to: "authentication#login"
    get "/dashboard", to: "dashboard#index"
    post "/register", to: "users#create"
    resources :facilities, param: :osm_id
    # Example: Route to get current admin user info
  end

  resources :facilities, only: [ :index ]

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
