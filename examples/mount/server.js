const express = require("express");
const fs = require("fs");
const path = require("path");

const app = express();
const PORT = 3000;

// Serve static files from the "public" directory
app.use(express.static(path.join(__dirname, "public")));

// Directory for Docker mount
const dataDir = path.join(__dirname, "data");

// Ensure the directory exists
if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir, { recursive: true });
}

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Endpoint to list files
app.get("/files", (req, res) => {
  fs.readdir(dataDir, (err, files) => {
    if (err) {
      return res.status(500).send("Error reading files.");
    }
    res.json(files);
  });
});

// Endpoint to read a file
app.get("/files/:filename", (req, res) => {
  const filePath = path.join(dataDir, req.params.filename);
  if (!fs.existsSync(filePath)) {
    return res.status(404).send("File not found.");
  }
  const content = fs.readFileSync(filePath, "utf-8");
  res.json({ content });
});

// Endpoint to write to a file
app.post("/files", (req, res) => {
  const { filename, content } = req.body;
  if (!filename || !content) {
    return res.status(400).send("Filename and content are required.");
  }
  const filePath = path.join(dataDir, filename);
  fs.writeFileSync(filePath, content, "utf-8");
  res.send("File saved successfully.");
});

// Start server
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
