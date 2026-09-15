import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

import { pool } from "../config/db.js";

const dir = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  "../../migrations",
);

for (const file of fs
  .readdirSync(dir)
  .filter((f) => f.endsWith(".sql"))
  .sort()) {
  const sql = fs
    .readFileSync(path.join(dir, file), "utf8")
    .replace(/^\uFEFF/, "");

  await pool.query(sql);
  console.log("migrated", file);
}

await pool.end();
