/**
 * The kit's STRICT "this request came from this machine" guard.
 *
 * Lives on its own so the two places that serve local-only surfaces — the
 * mounted routes (`/connect`, `/account`, `/status`) and the middleware's
 * direct route interception — enforce exactly the same rule. A second copy of
 * this logic is how a local-only surface quietly becomes a public one.
 */

const LOOPBACK = new Set(["127.0.0.1", "::1", "::ffff:127.0.0.1"]);

// Headers that a same-host reverse proxy will add to forwarded requests.
// Their presence means the TCP peer being loopback is due to the proxy hop,
// not a direct local connection — so the loopback guard must not grant access.
export const PROXY_HEADERS: readonly string[] = [
  "x-forwarded-for",
  "x-forwarded-host",
  "x-forwarded-proto",
  "x-real-ip",
  "forwarded",
];

/** Minimal request shape this guard reads. Deliberately structural so it
 *  accepts an Express request, a bare `http.IncomingMessage`, or a test stub. */
export interface LoopbackReqLike {
  socket?: { remoteAddress?: string } | undefined;
  connection?: { remoteAddress?: string } | undefined;
  headers?: Record<string, unknown> | undefined;
}

/**
 * True only for a request whose real TCP peer is loopback AND which carries no
 * proxy/forwarding headers.
 *
 * Deliberately does NOT honour `req.ip`. Express resolves `req.ip` from
 * X-Forwarded-For when the host app sets `trust proxy`, which makes the
 * loopback guard spoofable from the public internet. The real TCP peer is on
 * `req.socket.remoteAddress` (or the legacy `req.connection`), which the client
 * cannot rewrite.
 *
 * Fail-safe: any error answers `false` — a guard that throws must never end up
 * granting access.
 */
export function isDirectLoopback(req: LoopbackReqLike): boolean {
  try {
    const ip = req.socket?.remoteAddress ?? req.connection?.remoteAddress ?? "";
    if (!LOOPBACK.has(ip)) return false;

    // Even when the TCP peer is loopback, reject if proxy headers are present.
    // In a same-host reverse-proxy deployment every external request arrives
    // with a loopback peer address AND one or more forwarding headers set by
    // the proxy. A genuinely direct local connection has none of those headers.
    const headers = req.headers ?? {};
    return !PROXY_HEADERS.some((h) => headers[h] !== undefined);
  } catch {
    return false;
  }
}
