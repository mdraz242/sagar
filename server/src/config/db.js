import pg from "pg";
import dotenv from "dotenv";

dotenv.config();

const ssl =
  process.env.PGSSLMODE === "require"
    ? { rejectUnauthorized: false }
    : undefined;

export const pool = new pg.Pool({
  connectionString: process.env.DATABASE_URL,
  ssl,
});

export async function query(text, params) {
  return pool.query(text, params);
}
