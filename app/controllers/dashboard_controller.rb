# Simple form object to make Rails happy in demo
class TaskForm
  include ActiveModel::Model
  attr_accessor :title, :user_id
end


require 'ostruct'
class DashboardController < ApplicationController
  # For demo purposes, we assume user is "logged in" as a role
  # Replace with real authentication in production
  before_action :set_current_user
  before_action :load_shared_data

  def index
    @task ||= TaskForm.new
    # Determine which dashboard to show
    @active_view = params[:view]&.downcase || default_view

    # Manager or Employee selection
    if @active_view == "manager"
      @active_manager = params[:manager_id].present? ? @managers.find { |m| m.id.to_s == params[:manager_id] } : nil
      load_manager_tasks
    elsif @active_view == "employee"
      @active_employee = params[:employee_id].present? ? @employees.find { |e| e.id.to_s == params[:employee_id] } : nil
      load_employee_tasks
    else
      load_admin_tasks
    end

    set_dashboard_label

    # Ensure @task exists for form_with
    @task ||= OpenStruct.new(title: "", user_id: nil)
  end

  private

  # === Demo "current user" ===
  def set_current_user
    @current_user ||= OpenStruct.new(id: 1, name: "Admin John", role: "Admin")
  end

  # === Dummy users and tasks for demo ===
  def load_shared_data
    @employees = [
      OpenStruct.new(id: 1, name: "Employee Alice"),
      OpenStruct.new(id: 2, name: "Employee Bob"),
      OpenStruct.new(id: 3, name: "Employee Carol")
    ]

    @managers = [
      OpenStruct.new(id: 1, name: "Manager John"),
      OpenStruct.new(id: 2, name: "Manager Jane"),
      OpenStruct.new(id: 3, name: "Manager Mike")
    ]

    @tasks = [
      OpenStruct.new(title: "Prepare Report", user: @employees[0], manager_id: 1, status: "pending"),
      OpenStruct.new(title: "Site Inspection", user: @employees[1], manager_id: 2, status: "completed"),
      OpenStruct.new(title: "Client Meeting", user: @employees[2], manager_id: 1, status: "overdue")
    ]

    @ai_summary = "This is a demo AI summary of tasks for the team."
  end

  # Default view is Admin
  def default_view
    "admin"
  end

  # Labels for top of dashboard
  def set_dashboard_label
    @dashboard_label =
      case @active_view
      when "admin"
        "Admin Dashboard"
      when "manager"
        if @active_manager
          "Manager Dashboard (#{@active_manager.name})"
        else
          "Manager Dashboard (All Managers)"
        end
      when "employee"
        if @active_employee
          "Employee Dashboard (#{@active_employee.name})"
        else
          "Employee Dashboard (All Employees)"
        end
      else
        "Dashboard"
      end
  end

  # === Task loading ===
  def load_admin_tasks
    # Admin sees all tasks
    @tasks_to_show = @tasks
  end

  def load_manager_tasks
    # Filter by selected manager or show all
    if @active_manager
      @tasks_to_show = @tasks.select { |t| t.manager_id == @active_manager.id }
    else
      @tasks_to_show = @tasks
    end
  end

  def load_employee_tasks
    # Filter by selected employee or show all
    if @active_employee
      @tasks_to_show = @tasks.select { |t| t.user.id == @active_employee.id }
    else
      @tasks_to_show = @tasks
    end
  end
end
