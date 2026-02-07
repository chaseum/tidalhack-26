import express, { type Request, type Response } from "express";
import { assessRouter } from "./routes/assess";
import { chatRouter } from "./routes/chat";
import { healthRouter } from "./routes/health";

export function createServer() {
  const app = express();
  app.use(express.json());

  app.use("/health", healthRouter);
  app.use("/assess", assessRouter);
  app.use("/chat", chatRouter);

  app.use((_req: Request, res: Response) => {
    res.status(404).json({ error: "NotFound" });
  });

  return app;
}
