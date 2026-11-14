declare global {
  interface Window {
    GetParentResourceName?: () => string;
  }
}

export const isEnvBrowser = typeof window.GetParentResourceName !== "function";

export async function fetchNui<T = unknown>(event: string, data: unknown = {}): Promise<T | undefined> {
  if (isEnvBrowser) return;

  const resource = window.GetParentResourceName!();
  const response = await fetch(`https://${resource}/${event}`, {
    method: "POST",
    headers: { "Content-Type": "application/json; charset=UTF-8" },
    body: JSON.stringify(data),
  });

  return response.json();
}
