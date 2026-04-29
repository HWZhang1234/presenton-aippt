import { ConfigStorage } from './configStorage';

// Get user config headers for API requests
export function getUserConfigHeaders(): Record<string, string> {
  const config = ConfigStorage.load();
  if (!config) return {};

  const headers: Record<string, string> = {};
  
  // Add LLM configuration
  if (config.LLM) headers['X-LLM-Provider'] = config.LLM;
  if (config.OPENAI_API_KEY) headers['X-OpenAI-API-Key'] = config.OPENAI_API_KEY;
  if (config.OPENAI_MODEL) headers['X-OpenAI-Model'] = config.OPENAI_MODEL;
  if (config.GOOGLE_API_KEY) headers['X-Google-API-Key'] = config.GOOGLE_API_KEY;
  if (config.GOOGLE_MODEL) headers['X-Google-Model'] = config.GOOGLE_MODEL;
  if (config.ANTHROPIC_API_KEY) headers['X-Anthropic-API-Key'] = config.ANTHROPIC_API_KEY;
  if (config.ANTHROPIC_MODEL) headers['X-Anthropic-Model'] = config.ANTHROPIC_MODEL;
  if (config.CUSTOM_LLM_URL) headers['X-Custom-LLM-URL'] = config.CUSTOM_LLM_URL;
  if (config.CUSTOM_LLM_API_KEY) headers['X-Custom-LLM-API-Key'] = config.CUSTOM_LLM_API_KEY;
  if (config.CUSTOM_MODEL) headers['X-Custom-Model'] = config.CUSTOM_MODEL;
  if (config.OLLAMA_URL) headers['X-Ollama-URL'] = config.OLLAMA_URL;
  if (config.OLLAMA_MODEL) headers['X-Ollama-Model'] = config.OLLAMA_MODEL;
  if (config.CODEX_MODEL) headers['X-Codex-Model'] = config.CODEX_MODEL;
  
  // Add image provider configuration
  if (config.IMAGE_PROVIDER) headers['X-Image-Provider'] = config.IMAGE_PROVIDER;
  if (config.PEXELS_API_KEY) headers['X-Pexels-API-Key'] = config.PEXELS_API_KEY;
  if (config.PIXABAY_API_KEY) headers['X-Pixabay-API-Key'] = config.PIXABAY_API_KEY;
  if (config.DISABLE_IMAGE_GENERATION !== undefined) {
    headers['X-Disable-Image-Generation'] = String(config.DISABLE_IMAGE_GENERATION);
  }
  
  return headers;
}

// Utility to get the FastAPI base URL
export function getFastAPIUrl(): string {
  // Prefer Electron-preload env when available
  if (typeof window !== "undefined" && (window as any).env?.NEXT_PUBLIC_FAST_API) {
    return (window as any).env.NEXT_PUBLIC_FAST_API;
  }

  const queryFastApiUrl = getFastApiUrlFromQuery();
  if (queryFastApiUrl) {
    return queryFastApiUrl;
  }

  // Check Next.js public env variable (works in both server and client)
  if (typeof process !== "undefined" && process.env.NEXT_PUBLIC_FAST_API) {
    return process.env.NEXT_PUBLIC_FAST_API;
  }

  // In Docker/production, use relative URL (empty string) so nginx can proxy
  // In Electron, use localhost
  const isElectron = typeof window !== "undefined" && (window as any).electron;
  return isElectron ? "http://127.0.0.1:8000" : "";
}

function getFastApiUrlFromQuery(): string | null {
  if (typeof window === "undefined") return null;
  try {
    const params = new URLSearchParams(window.location.search);
    const value = params.get("fastapiUrl");
    if (!value) return null;

    const parsed = new URL(value);
    if (parsed.protocol !== "http:" && parsed.protocol !== "https:") {
      return null;
    }
    return parsed.origin;
  } catch {
    return null;
  }
}

function isAbsoluteHttpUrl(path: string): boolean {
  return /^https?:\/\//i.test(path);
}

function withLeadingSlash(path: string): string {
  return path.startsWith("/") ? path : `/${path}`;
}

function isElectronRuntime(): boolean {
  return typeof window !== "undefined" && !!(window as any).electron;
}

// Utility to construct API URL that works in both web and Electron.
export function getApiUrl(path: string): string {
  if (isAbsoluteHttpUrl(path)) {
    return path;
  }

  const normalizedPath = withLeadingSlash(path);
  const isFastApiEndpoint = normalizedPath.startsWith("/api/v1/");
  const hasWindowFastApi = typeof window !== "undefined" && !!(window as any).env?.NEXT_PUBLIC_FAST_API;
  const hasQueryFastApi = !!getFastApiUrlFromQuery();

  // In web/docker, /api/v1 is typically reverse-proxied by the web server.
  // In Electron, Next and FastAPI run on different ports, so use FastAPI base URL.
  if (
    isFastApiEndpoint &&
    (isElectronRuntime() || !!process.env.NEXT_PUBLIC_FAST_API || hasWindowFastApi || hasQueryFastApi)
  ) {
    return `${getFastAPIUrl()}${normalizedPath}`;
  }

  return normalizedPath;
}

function hasBackendAssetPrefix(path: string): boolean {
  return path.startsWith("/static/") || path.startsWith("/app_data/");
}

// Resolve backend-served asset paths to the FastAPI origin in Electron/runtime split-port setups.
export function resolveBackendAssetUrl(path?: string): string {
  if (!path) return "";

  const trimmedPath = path.trim();
  if (!trimmedPath) return "";

  if (
    trimmedPath.startsWith("data:") ||
    trimmedPath.startsWith("blob:") ||
    trimmedPath.startsWith("file:")
  ) {
    return trimmedPath;
  }

  if (isAbsoluteHttpUrl(trimmedPath)) {
    try {
      const parsed = new URL(trimmedPath);
      if (hasBackendAssetPrefix(parsed.pathname)) {
        // Use getApiUrl to respect nginx proxy in Docker environments
        return getApiUrl(`${parsed.pathname}${parsed.search}${parsed.hash}`);
      }
      return trimmedPath;
    } catch {
      return trimmedPath;
    }
  }

  const normalizedPath = withLeadingSlash(trimmedPath);
  if (hasBackendAssetPrefix(normalizedPath)) {
    // Use getApiUrl to respect nginx proxy in Docker environments
    return getApiUrl(normalizedPath);
  }

  return trimmedPath;
}
