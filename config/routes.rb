Rails.application.routes.draw do
  resources :dashboard, only: [:index] do
    collection do
      post :create_task
      post :create_manager
      post :assign_employee
    end
    member do
      patch :mark_complete
      patch :update_task
    end
  end

  get 'employee_dashboard', to: 'employee_dashboard#index'

  resources :tasks, only: [:index, :create, :update, :edit, :destroy] do
    patch :complete, on: :member
  end

  resources :users, only: [:index]

  get "/employee_dashboard", to: "employee_dashboard#index"

  get "up" => "rails/health#show", as: :rails_health_check

  root "dashboard#index"
end
