// app.js – API: Redis messages + PostgreSQL users
import express from "express";
import { createClient as createRedisClient } from "redis";
import pkg from "pg";

const { Pool } = pkg;
const app   = express();
const port  = process.env.PORT || 3000;

// ---------- Redis ----------
const redisUrl = process.env.REDIS_URL || "redis://redis:6379";
const redis = createRedisClient({ url: redisUrl });
redis.on("error", (err) => console.error("Redis error:", err));
await redis.connect();

// ---------- PostgreSQL ----------
const pgPool = new Pool({ connectionString: process.env.DATABASE_URL });
await pgPool.query(`
  CREATE TABLE IF NOT EXISTS users (
    id      SERIAL PRIMARY KEY,
    name    TEXT NOT NULL,
    email   TEXT UNIQUE NOT NULL
  )
`);

// ---------- Express setup ----------
app.use(express.json());

/* ========= Messages (Redis) ========= */

app.post("/messages", async (req, res) => {
  const { message } = req.body || {};
  if (!message) return res.status(400).json({ error: "Message field is required" });

  await redis.rPush("messages", message);
  res.status(201).json({ status: "added", message });
});

app.get("/messages", async (_req, res) => {
  const messages = await redis.lRange("messages", 0, -1);
  res.json({ count: messages.length, messages });
});

/* ========= Users (PostgreSQL) ========= */

app.post("/users", async (req, res) => {
  const { name, email } = req.body || {};
  if (!name || !email) {
    return res.status(400).json({ error: "Name and email fields are required" });
  }

  try {
    const { rows } = await pgPool.query(
      "INSERT INTO users (name, email) VALUES ($1, $2) RETURNING *",
      [name, email]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    if (err.code === "23505") { // unique_violation
      return res.status(409).json({ error: "User with given email already exists" });
    }
    console.error(err);
    res.status(500).json({ error: "Server error" });
  }
});

app.get("/users", async (_req, res) => {
  const { rows } = await pgPool.query("SELECT * FROM users ORDER BY id");
  res.json({ count: rows.length, users: rows });
});

/* ===================================== */

app.listen(port, "0.0.0.0", () =>
  console.log(`Server listening on http://0.0.0.0:${port}`)
);
