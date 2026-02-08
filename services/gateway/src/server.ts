import express, { type Request, type Response } from 'express';
import { sendError } from "./error-response";
import { errorHandler } from "./middleware/errors";
import { requestLogger } from "./middleware/logger";
import { rateLimit } from "./middleware/ratelimit";
import { assessRouter } from './routes/assess';
import { authRouter } from './routes/auth';
import { chatRouter } from './routes/chat';
import { diaryRouter } from './routes/diary';
import { healthRouter } from './routes/health';
import { photosRouter } from './routes/photos';
import { planRouter } from "./routes/plan";

export function createServer() {
  const app = express();

  app.use(requestLogger);
  app.use(rateLimit);
  app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET,POST,PUT,PATCH,DELETE,OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-User-Id');

    if (req.method === 'OPTIONS') {
      return res.sendStatus(204);
    }

    return next();
  });

  app.use(express.json({ limit: '15mb' }));

  app.use('/health', healthRouter);
  app.use('/assess', assessRouter);
  app.use("/plan", planRouter);
  app.use('/chat', chatRouter);
  app.use('/auth', authRouter);
  app.use('/diary', diaryRouter);
  app.use('/photos', photosRouter);

  app.use((_req: Request, res: Response) => {
    sendError(res, 404, 'NotFound', "Route not found");
  });

  app.use(errorHandler);

  return app;
}
