const express = require("express");
const path = require("path");

const app = express();
const PORT = process.env.PORT || 3000;

// Serve static files from /public
app.use(express.static(path.join(__dirname, "public")));

app.get("/health", (req, res) => {
  res.json({ status: "frontend-ok" });
});

app.listen(PORT, () => {
  console.log(`Frontend running at http://localhost:${PORT}`);
});
