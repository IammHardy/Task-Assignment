Rails.application.routes.draw do
  # Dashboard & AI
  resources :dashboard, only: [:index] do
    collection do
      post :ai_refresh
    end
  end


resources :tasks, only: [:index, :create, :update, :edit, :destroy] do
  patch :complete, on: :member
end




  # Users
  resources :users, only: [:index]

  # Employees
 
  get "/employee_dashboard", to: "employee_dashboard#index"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Root path
  root "dashboard#index"
end
