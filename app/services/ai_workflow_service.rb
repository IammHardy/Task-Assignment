# app/services/ai_workflow_service.rb
class AiWorkflowService
  require "openai"

  CACHE_EXPIRY = 30.minutes

  def initialize(tasks, employees)
    @tasks = tasks
    @employees = employees
    @client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
    @industry = detect_industry
  end

  # Public API: returns [summary, suggestions[]]
  def progress_and_suggestions
    Rails.cache.fetch(cache_key, expires_in: CACHE_EXPIRY) do
      [
        progress_summary,
        suggest_tasks
      ]
    end
  end

  private

  # ✅ Industry should come from admin/manager, not employees
  def detect_industry
    admin = User.find_by(role: "Manager") || User.find_by(role: "Admin")
    industry = admin&.industry&.downcase
    %w[law medical services].include?(industry) ? industry : "services"
  end

  # ✅ Single, correct summary method
  def progress_summary
    prompt = industry_context(:summary)
    prompt += task_list
    prompt += "\n\nHighlight overdue or critical tasks, workload imbalance, and risks."

    result = call_openai(prompt)
    result || "AI is temporarily unavailable. Please try again."
  end

  # ✅ Safe suggestions method
  def suggest_tasks
    prompt = industry_context(:suggestions)
    prompt += task_list
    prompt += "\n\nProvide actionable improvement suggestions."

    response = call_openai(prompt)
    return [] if response.blank?

    response
      .split("\n")
      .map(&:strip)
      .reject(&:empty?)
  end

  def task_list
  @tasks.map do |task|
    "- #{task.title} (#{task.description || 'No description'}), assigned to #{task.user&.name || 'Unassigned'}, status: #{task.status}, due: #{task.due_date}"
  end.join("\n")
end


  def industry_context(type)
    case @industry
    when "law"
      base = "This is a law firm managing cases, filings, meetings, and legal research."
    when "medical"
      base = "This is a medical facility managing patient appointments, procedures, and staff schedules."
    else
      base = "This is a service company managing client jobs like plumbing, electrical, roofing, or landscaping."
    end

    if type == :summary
      "#{base}\nSummarize the team's progress based on these tasks:\n"
    else
      "#{base}\nSuggest improvements or new tasks based on the current workload:\n"
    end
  end

  # ✅ Centralized OpenAI call with proper error handling
  def call_openai(prompt)
    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.3
      }
    )

    response.dig("choices", 0, "message", "content")
  rescue Faraday::TooManyRequestsError
    nil
  rescue Faraday::UnauthorizedError
    raise "Invalid OpenAI API key"
  rescue StandardError => e
    Rails.logger.error("AI error: #{e.message}")
    nil
  end

  # ✅ Efficient cache key
  def cache_key
    latest_task_update = @tasks.maximum(:updated_at)&.to_i
    latest_employee_update = @employees.maximum(:updated_at)&.to_i

    "ai_workflow_#{@industry}_#{latest_task_update}_#{latest_employee_update}"
  end
end
