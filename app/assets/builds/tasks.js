document.addEventListener("DOMContentLoaded", () => {
  const form = document.getElementById("new-task-form");
  const msg = document.getElementById("task-msg");
  const table = document.getElementById("task-table");

  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    const formData = new FormData(form);
    const data = Object.fromEntries(formData.entries());

    const res = await fetch("/tasks", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ task: data })
    });

    const result = await res.json();
    if (result.status === "success") {
      msg.innerText = "Task created!";
      const t = result.task;
      table.innerHTML += `
        <tr>
          <td>${t.title}</td>
          <td>${t.user_id}</td>
          <td>${t.status}</td>
          <td>${t.due_date}</td>
        </tr>
      `;
      form.reset();
    } else {
      msg.style.color = "red";
      msg.innerText = "Error: " + result.errors.join(", ");
    }
  });
});

document.addEventListener("turbo:submit-end", function(event) {
  if (event.detail.success) {
    const msgDiv = document.getElementById("task-msg");
    if (msgDiv) {
      msgDiv.innerText = "Task updated successfully!";
      setTimeout(() => { msgDiv.innerText = ""; }, 3000);
    }
  }
});

