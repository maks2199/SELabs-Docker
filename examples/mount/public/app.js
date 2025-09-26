// const apiBase = 'http://localhost:3000';
// const host = process.env.HOST;
// const port = process.env.PORT;
// const url = `http://${host}:${port}`;
let url;

document.addEventListener("DOMContentLoaded", async () => {
  // Load config.json
  const configResp = await fetch("/config.json");
  const config = await configResp.json();
  url = `http://${config.host}:${config.port}`;

  const writeForm = document.getElementById("write-form");
  const refreshBtn = document.getElementById("refresh-btn");
  const fileList = document.getElementById("file-list");
  const readForm = document.getElementById("read-form");
  const fileContent = document.getElementById("file-content");

  // Write file
  writeForm.addEventListener("submit", async (e) => {
    e.preventDefault();
    const filename = document.getElementById("filename").value;
    const content = document.getElementById("content").value;

    const response = await fetch(`${url}/files`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ filename, content }),
    });

    if (response.ok) {
      alert("File saved successfully!");
      writeForm.reset();
      loadFileList();
    } else {
      alert("Failed to save the file.");
    }
  });

  // Load file list
  const loadFileList = async () => {
    const response = await fetch(`${url}/files`);
    if (response.ok) {
      const files = await response.json();
      fileList.innerHTML = files.map((file) => `<li>${file}</li>`).join("");
    } else {
      fileList.innerHTML = "<li>Failed to load files.</li>";
    }
  };

  // Refresh file list
  refreshBtn.addEventListener("click", loadFileList);

  // Read file
  readForm.addEventListener("submit", async (e) => {
    e.preventDefault();
    const filename = document.getElementById("read-filename").value;

    const response = await fetch(`${url}/files/${filename}`);
    if (response.ok) {
      const { content } = await response.json();
      fileContent.textContent = content;
    } else {
      fileContent.textContent = "Failed to read the file.";
    }
  });

  // Initial file list load
  loadFileList();
});
