const express = require("express");
const path = require("path");
const fs = require("fs");

const app = express();
const PORT = process.env.PORT || 3000;

// Backend configuration from environment variables
const BACKEND_HOST = process.env.BACKEND_HOST || "backend";
const BACKEND_PORT = process.env.BACKEND_PORT || "8080";
const BACKEND_URL = `http://${BACKEND_HOST}:${BACKEND_PORT}`;

// Serve static files from /public
app.use(express.static(path.join(__dirname, "public")));

// Serve the main HTML file with environment variables injected
app.get("/", (req, res) => {
  const htmlPath = path.join(__dirname, "public", "index.html");
  let html = fs.readFileSync(htmlPath, "utf8");

  // Replace placeholder with actual backend URL
  html = html.replace("{{BACKEND_URL}}", BACKEND_URL);

  res.send(html);
});

app.get("/health", (req, res) => {
  res.json({ status: "frontend-ok" });
});

app.listen(PORT, () => {
  console.log(`Frontend running at http://localhost:${PORT}`);
  console.log(`Backend URL: ${BACKEND_URL}`);
});
