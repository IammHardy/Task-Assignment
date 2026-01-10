# db/seeds.rb

# -----------------------------
# Keep old users
# -----------------------------
User.find_or_create_by!(email: "manager@example.com") do |u|
  u.name = "Manager John"
  u.role = "Manager"
end

User.find_or_create_by!(email: "alice@example.com") do |u|
  u.name = "Employee Alice"
  u.role = "Employee"
end

User.find_or_create_by!(email: "bob@example.com") do |u|
  u.name = "Employee Bob"
  u.role = "Employee"
end

# -----------------------------
# Create Managers for each industry
# -----------------------------
manager_law = User.find_or_create_by!(email: "law_manager@example.com") do |u|
  u.name = "Law Manager"
  u.role = "Manager"
  u.industry = "law"
end

manager_med = User.find_or_create_by!(email: "medical_manager@example.com") do |u|
  u.name = "Medical Manager"
  u.role = "Manager"
  u.industry = "medical"
end

manager_serv = User.find_or_create_by!(email: "services_manager@example.com") do |u|
  u.name = "Services Manager"
  u.role = "Manager"
  u.industry = "services"
end

# -----------------------------
# Create Employees under each manager
# -----------------------------
law_emp1 = User.find_or_create_by!(email: "law_emp1@example.com") do |u|
  u.name = "Law Employee 1"
  u.role = "Employee"
  u.manager_id = manager_law.id if u.respond_to?(:manager_id)
end

law_emp2 = User.find_or_create_by!(email: "law_emp2@example.com") do |u|
  u.name = "Law Employee 2"
  u.role = "Employee"
  u.manager_id = manager_law.id if u.respond_to?(:manager_id)
end

med_emp1 = User.find_or_create_by!(email: "med_emp1@example.com") do |u|
  u.name = "Med Employee 1"
  u.role = "Employee"
  u.manager_id = manager_med.id if u.respond_to?(:manager_id)
end

med_emp2 = User.find_or_create_by!(email: "med_emp2@example.com") do |u|
  u.name = "Med Employee 2"
  u.role = "Employee"
  u.manager_id = manager_med.id if u.respond_to?(:manager_id)
end

serv_emp1 = User.find_or_create_by!(email: "serv_emp1@example.com") do |u|
  u.name = "Serv Employee 1"
  u.role = "Employee"
  u.manager_id = manager_serv.id if u.respond_to?(:manager_id)
end

serv_emp2 = User.find_or_create_by!(email: "serv_emp2@example.com") do |u|
  u.name = "Serv Employee 2"
  u.role = "Employee"
  u.manager_id = manager_serv.id if u.respond_to?(:manager_id)
end

# -----------------------------
# Create sample tasks for demo
# -----------------------------
tasks_data = [
  { title: "Case Filing", description: "File legal documents for client X", user: law_emp1, status: "pending", due_date: 2.days.from_now },
  { title: "Client Meeting", description: "Meet client Y regarding contract", user: law_emp2, status: "in_progress", due_date: 1.day.from_now },
  { title: "Patient Checkup", description: "Checkup for patient Z", user: med_emp1, status: "pending", due_date: 1.day.from_now },
  { title: "Surgery Prep", description: "Prepare operation room", user: med_emp2, status: "in_progress", due_date: 3.days.from_now },
  { title: "Roof Inspection", description: "Inspect roof at client site", user: serv_emp1, status: "pending", due_date: 2.days.from_now },
  { title: "Electrical Repair", description: "Fix wiring issue at client site", user: serv_emp2, status: "completed", due_date: 1.day.ago }
]

tasks_data.each do |t|
  Task.find_or_create_by!(title: t[:title], user: t[:user]) do |task|
    task.description = t[:description]
    task.status = t[:status]
    task.due_date = t[:due_date]
  end
end

puts "✅ Seeded users, employees, and demo tasks successfully!"
