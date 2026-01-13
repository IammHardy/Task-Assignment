class DashboardController < ApplicationController
  # Index action
  def index
    @active_view = params[:view]&.downcase || default_view
    @active_manager = if @active_view == "manager" && params[:manager_id].present?
                        User.find_by(id: params[:manager_id])
                      else
                        nil
                      end

    load_dashboard_data
    set_dashboard_label

    # Ensure @task is always a real Task object for the form
    @task ||= Task.new
  end

  private

  # This must be defined in the controller
  def default_view
    "admin" # make Admin the default dashboard
  end

  def load_dashboard_data
    # Dummy data for demo
    @managers  = User.where(role: "Manager") # or dummy OpenStructs
    @employees = User.where(role: "Employee")
    @industries = Industry.all

    case @active_view
    when "admin"
      @tasks = Task.all
    when "manager"
      @tasks = Task.all
    when "employee"
      @tasks = Task.where(user_id: 1) # demo employee tasks
    else
      @tasks = Task.none
    end
  end

  def set_dashboard_label
    @dashboard_label =
      case @active_view
      when "admin"
        "Admin Dashboard"
      when "manager"
        @active_manager ? "Manager Dashboard (#{@active_manager.name})" : "Manager Dashboard (All Managers)"
      when "employee"
        "Employee Dashboard"
      else
        "Dashboard"
      end
  end
end
