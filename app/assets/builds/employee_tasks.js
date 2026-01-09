document.addEventListener("DOMContentLoaded", () => {
  const csrfToken = document.querySelector('meta[name="csrf-token"]').content;

  document.querySelectorAll(".update-btn").forEach(button => {
    button.addEventListener("click", (e) => {
      const row = e.target.closest("tr");
      const taskId = row.dataset.taskId;
      const status = row.querySelector(".status-select").value;

      fetch(`/tasks/${taskId}`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Accept": "text/vnd.turbo-stream.html", // Turbo Stream response
          "X-CSRF-Token": csrfToken           // ✅ Add this
        },
        body: JSON.stringify({ task: { status: status } })
      });
    });
  });
});
