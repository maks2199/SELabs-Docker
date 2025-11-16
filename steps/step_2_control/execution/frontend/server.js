const express = require("express");
const path = require("path");
const fs = require("fs");
const { createProxyMiddleware } = require("http-proxy-middleware");

const app = express();
const PORT = process.env.PORT || 3000;

// Backend configuration from environment variables
const BACKEND_HOST = process.env.BACKEND_HOST || "backend";
const BACKEND_PORT = process.env.BACKEND_PORT || "8080";
const BACKEND_URL = `http://${BACKEND_HOST}:${BACKEND_PORT}`;

// Proxy configuration for backend API
const proxyOptions = {
  target: BACKEND_URL,
  changeOrigin: true,
  pathRewrite: {
    "^/api": "", // Remove /api prefix when forwarding to backend
  },
  onError: (err, req, res) => {
    console.error("Proxy error:", err);
    res.status(500).json({ error: "Backend service unavailable" });
  },
};

// Proxy all /api requests to backend
app.use("/api", createProxyMiddleware(proxyOptions));

// Serve the main HTML file with environment variables injected
app.get("/", (req, res) => {
  const htmlPath = path.join(__dirname, "public", "index.html");
  let html = fs.readFileSync(htmlPath, "utf8");

  // Replace placeholder with local proxy URL
  html = html.replace("{{BACKEND_URL}}", "/api");

  res.send(html);
});

// Serve static files from /public (except index.html which is handled above)
app.use(
  express.static(path.join(__dirname, "public"), {
    index: false, // Don't serve index.html automatically
  })
);

app.get("/health", (req, res) => {
  res.json({ status: "frontend-ok" });
});

app.listen(PORT, () => {
  console.log(`Frontend running at http://localhost:${PORT}`);
  console.log(`Backend URL: ${BACKEND_URL}`);
});
