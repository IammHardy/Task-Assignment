Rails.application.routes.draw do
  # Dashboard
  resources :dashboard, only: [:index] do
    collection do
      post :create_task       # create task for admin/manager
      patch :mark_complete    # employee marks task complete
      post :ai_refresh        # your AI refresh route
      post :assign_manager    # assign manager to employee
    end
  end

  # Tasks (optional, if needed elsewhere)
  resources :tasks, only: [:index, :create, :update, :edit, :destroy] do
    patch :complete, on: :member
  end

  # Users
  resources :users, only: [:index]

  # Employee dashboard
  get "/employee_dashboard", to: "employee_dashboard#index"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Root
  root "dashboard#index"
end
