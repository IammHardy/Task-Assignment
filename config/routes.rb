Rails.application.routes.draw do
  # Dashboard
resources :dashboard, only: [:index] do
  collection do
    patch :mark_complete    # employee marking task complete
    post  :create_task
    post  :assign_manager
  end
  member do
    patch :update_task      # updating a task for admin/manager
  end
end



  get 'employee_dashboard', to: 'employee_dashboard#index'


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
