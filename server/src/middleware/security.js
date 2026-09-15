import cors from "cors";
import helmet from "helmet";
import rateLimit from "express-rate-limit";

function corsOrigin(origin, callback) {
  const configured = process.env.CORS_ORIGIN || "";
  const allowedOrigins = configured
    .split(",")
    .map((value) => value.trim())
    .filter(Boolean);

  if (allowedOrigins.includes("*")) {
    callback(null, true);
    return;
  }

  if (!origin) {
    callback(null, true);
    return;
  }

  if (allowedOrigins.includes(origin)) {
    callback(null, true);
    return;
  }

  callback(new Error("Not allowed by CORS"));
}

export const security = [
  helmet({
    contentSecurityPolicy: {
      directives: {
        ...helmet.contentSecurityPolicy.getDefaultDirectives(),
        "script-src": ["'self'", "'unsafe-inline'", "https:"],
        "script-src-attr": ["'unsafe-inline'"],
        "style-src": ["'self'", "'unsafe-inline'", "https:"],
        "img-src": ["'self'", "data:", "https:", "blob:"],
        "connect-src": ["'self'", "ws:", "wss:", "http:", "https:"],
      },
    },
  }),
  cors({ origin: corsOrigin }),
  rateLimit({
    windowMs: 15 * 60 * 1000,
    limit: 300,
    standardHeaders: true,
    legacyHeaders: false,
  }),
];
