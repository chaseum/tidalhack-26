import express, { type Request, type Response } from "express";
import { errorHandler } from "./errors";
import { requestLogger } from "./logger";
import { assessRouter } from "./routes/assess";
import { chatRouter } from "./routes/chat";
import { healthRouter } from "./routes/health";
import { planRouter } from "./routes/plan";

export function createServer() {
  const app = express();
  app.use(requestLogger);
  app.use(express.json());

  app.use("/health", healthRouter);
  app.use("/assess", assessRouter);
  app.use("/plan", planRouter);
  app.use("/chat", chatRouter);

  app.use((_req: Request, res: Response) => {
    res.status(404).json({ error: "NotFound", detail: "Route not found" });
  });

  app.use(errorHandler);

  return app;
}
