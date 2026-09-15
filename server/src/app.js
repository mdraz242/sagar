import express from "express";
import morgan from "morgan";
import path from "path";
import { fileURLToPath } from "url";
import routes from "./routes/index.js";
import { security } from "./middleware/security.js";
import { errorHandler, notFoundHandler } from "./middleware/errorHandler.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const serverRoot = path.resolve(__dirname, "..");
const repoRoot = path.resolve(__dirname, "../..");

export const app = express();

app.set("trust proxy", 1);
app.use(security);
app.use(
  express.json({
    limit: "1mb",
    verify: (req, _res, buf) => {
      req.rawBody = buf.toString("utf8");
    },
  }),
);
app.use(morgan("combined"));

app.get("/health", (_req, res) =>
  res.json({ success: true, data: { status: "ok", timestamp: new Date().toISOString() } }),
);

// Unified workspace portal at root
app.get("/", (_req, res) => {
  res.sendFile(path.join(serverRoot, "public/portal.html"));
});

app.use("/uploads", express.static(path.join(serverRoot, "uploads")));
app.use("/admin", express.static(path.join(serverRoot, "public/admin")));
app.use(
  "/legal",
  express.static(path.join(serverRoot, "public/legal"), { extensions: ["html"] }),
);
app.use("/preview", express.static(path.join(repoRoot, "preview")));
app.use("/mobile/assets", express.static(path.join(repoRoot, "mobile/assets")));

app.use("/api", routes);
app.use(notFoundHandler);
app.use(errorHandler);
