import type { Request } from "express";
import { Router } from "express";
import { sendError } from "../error-response";
import { mlAssess } from "../ml";
import { assessRequestSchema, assessResponseSchema } from "../validators/contracts";

export const assessRouter = Router();

type MultipartPart = {
  contentType?: string;
  data: Buffer;
  filename?: string;
  name?: string;
};

const readRequestBuffer = (req: Request): Promise<Buffer> =>
  new Promise((resolve, reject) => {
    const chunks: Buffer[] = [];
    req.on("data", (chunk: Buffer | string) => {
      chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
    });
    req.on("end", () => resolve(Buffer.concat(chunks)));
    req.on("error", reject);
  });

const parseBoundary = (contentType: string): string | null => {
  const match = contentType.match(/boundary=(?:"([^"]+)"|([^;]+))/i);
  return match?.[1] ?? match?.[2] ?? null;
};

const parseMultipartParts = (rawBody: Buffer, boundary: string): MultipartPart[] => {
  const sections = rawBody.toString("latin1").split(`--${boundary}`);
  const parts: MultipartPart[] = [];

  for (const section of sections) {
    if (!section || section === "--" || section === "--\r\n") {
      continue;
    }

    let normalized = section;
    if (normalized.startsWith("\r\n")) {
      normalized = normalized.slice(2);
    }
    if (normalized.endsWith("--")) {
      normalized = normalized.slice(0, -2);
    }
    if (normalized.endsWith("\r\n")) {
      normalized = normalized.slice(0, -2);
    }

    const delimiterIndex = normalized.indexOf("\r\n\r\n");
    if (delimiterIndex < 0) {
      continue;
    }

    const headerLines = normalized.slice(0, delimiterIndex).split("\r\n");
    let name: string | undefined;
    let filename: string | undefined;
    let contentType: string | undefined;

    for (const headerLine of headerLines) {
      const [rawKey, ...rest] = headerLine.split(":");
      const key = rawKey?.trim().toLowerCase();
      const value = rest.join(":").trim();
      if (!key || !value) {
        continue;
      }

      if (key === "content-type") {
        contentType = value;
      }

      if (key === "content-disposition") {
        const nameMatch = value.match(/name="([^"]+)"/i);
        const fileMatch = value.match(/filename="([^"]+)"/i);
        name = nameMatch?.[1];
        filename = fileMatch?.[1];
      }
    }

    const content = normalized.slice(delimiterIndex + 4);
    parts.push({
      name,
      filename,
      contentType,
      data: Buffer.from(content, "latin1")
    });
  }

  return parts;
};

assessRouter.post("/", async (req, res, next) => {
  const contentType = req.headers["content-type"];
  if (!contentType || !contentType.toLowerCase().startsWith("multipart/form-data")) {
    return sendError(
      res,
      400,
      "ValidationError",
      "content-type: Expected multipart/form-data request"
    );
  }

  const boundary = parseBoundary(contentType);
  if (!boundary) {
    return sendError(res, 400, "ValidationError", "content-type: Missing multipart boundary");
  }

  try {
    const rawBody = await readRequestBuffer(req);
    const parts = parseMultipartParts(rawBody, boundary);
    const imagePart = parts.find((part) => part.name === "image");
    const requestPart = parts.find((part) => part.name === "request");

    if (!imagePart || imagePart.data.length === 0) {
      return sendError(res, 400, "ValidationError", "image: image file is required");
    }

    if (!requestPart || requestPart.data.length === 0) {
      return sendError(res, 400, "ValidationError", "request: request JSON part is required");
    }

    let parsedRequestJson: unknown;
    try {
      parsedRequestJson = JSON.parse(requestPart.data.toString("utf8"));
    } catch {
      return sendError(res, 400, "ValidationError", "request: request must be valid JSON");
    }

    const parsedRequest = assessRequestSchema.safeParse(parsedRequestJson);
    if (!parsedRequest.success) {
      const message = parsedRequest.error.issues
        .map((issue) => `${issue.path.join(".") || "request"}: ${issue.message}`)
        .join("; ");
      return sendError(res, 400, "ValidationError", message || "request: invalid payload");
    }

    const formData = new FormData();
    formData.append(
      "image",
      new Blob([new Uint8Array(imagePart.data)], {
        type: imagePart.contentType ?? "application/octet-stream"
      }),
      imagePart.filename ?? "upload.bin"
    );
    formData.append("request", JSON.stringify(parsedRequest.data));

    const upstreamResponse = await mlAssess(formData);
    const response = assessResponseSchema.parse(upstreamResponse);
    res.status(200).json(response);
  } catch (error) {
    next(error);
  }
});
