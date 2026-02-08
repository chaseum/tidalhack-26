const MAX_ERROR_TEXT_LENGTH = 500;

const truncate = (text: string, maxLength: number): string => {
  if (text.length <= maxLength) {
    return text;
  }
  return `${text.slice(0, maxLength)}...`;
};

const readErrorText = async (response: Response): Promise<string> => {
  try {
    return truncate(await response.text(), MAX_ERROR_TEXT_LENGTH);
  } catch {
    return "<failed to read response body>";
  }
};

export async function requestMl(
  baseUrl: string,
  path: string,
  init: RequestInit,
  timeoutMs: number
): Promise<unknown> {
  const response = await fetch(`${baseUrl}${path}`, {
    ...init,
    signal: AbortSignal.timeout(timeoutMs)
  });

  if (!response.ok) {
    const responseText = await readErrorText(response);
    const upstreamError = new Error(
      `ML request failed: status=${response.status} body=${responseText}`
    ) as Error & { status?: number; code?: string };
    upstreamError.status = response.status >= 400 && response.status <= 599 ? response.status : 502;
    upstreamError.code = "UpstreamError";
    throw upstreamError;
  }

  return response.json();
}
