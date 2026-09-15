import fs from "fs";
import path from "path";
import multer from "multer";
import { ApiError } from "../../utils/apiError.js";
import { logAdminActivity } from "./helpers.js";

const isVercel = !!process.env.VERCEL;
const uploadRoot = isVercel ? "/tmp/uploads" : path.resolve("uploads");
try {
  if (!fs.existsSync(uploadRoot)) fs.mkdirSync(uploadRoot, { recursive: true });
} catch (_) {
  // Vercel read-only filesystem – uploads go to cloud storage anyway
}

export const uploadMiddleware = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    if (!file.mimetype.startsWith("image/"))
      return cb(new ApiError(422, "Only image uploads are allowed"));
    cb(null, true);
  },
}).single("file");

export async function upload(req, res, next) {
  try {
    if (!req.file) throw new ApiError(422, "file is required");
    const safe = req.file.originalname.replace(/[^a-zA-Z0-9.\-_]/g, "-");
    const filename = `${Date.now()}-${safe}`;
    const storageUrl = process.env.SUPABASE_URL;
    const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
    const bucket = process.env.SUPABASE_STORAGE_BUCKET || "vyparhub-assets";
    let filePath;
    let url;

    if (storageUrl && serviceKey) {
      filePath = `admin/${filename}`;
      const uploadUrl = `${storageUrl.replace(/\/$/, "")}/storage/v1/object/${bucket}/${filePath}`;
      const response = await fetch(uploadUrl, {
        method: "POST",
        headers: {
          authorization: `Bearer ${serviceKey}`,
          apikey: serviceKey,
          "content-type": req.file.mimetype,
          "x-upsert": "true",
        },
        body: req.file.buffer,
      });
      if (!response.ok) {
        const text = await response.text();
        throw new ApiError(502, "Cloud storage upload failed", text);
      }
      url = `${storageUrl.replace(/\/$/, "")}/storage/v1/object/public/${bucket}/${filePath}`;
    } else if (process.env.NODE_ENV === "production") {
      throw new ApiError(500, "Persistent cloud storage is not configured");
    } else {
      await fs.promises.writeFile(
        path.join(uploadRoot, filename),
        req.file.buffer,
      );
      filePath = `/uploads/${filename}`;
      const origin = `${req.protocol}://${req.get("host")}`;
      url = `${origin}${filePath}`;
    }

    const origin = `${req.protocol}://${req.get("host")}`;
    await logAdminActivity(req, "upload", "file", null, null, {
      path: filePath,
      url,
      storage: storageUrl ? "supabase" : "local",
    });
    res
      .status(201)
      .json({
        success: true,
        data: { path: url.startsWith(origin) ? filePath : url, url },
      });
  } catch (e) {
    next(e);
  }
}
