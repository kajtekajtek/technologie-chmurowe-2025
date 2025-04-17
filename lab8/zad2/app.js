import express from "express";
import { createClient } from "redis";

const app  = express();
const port = 3000;

const redisUrl = process.env.REDIS_URL || "redis://redis:6379";
const redis    = createClient({ url: redisUrl });

redis.on("error", err => console.error("Redis error:", err));
await redis.connect();

app.use(express.json());

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

app.listen(port, "0.0.0.0", () =>
  console.log(`Server listening on http://0.0.0.0:${port}`)
);

