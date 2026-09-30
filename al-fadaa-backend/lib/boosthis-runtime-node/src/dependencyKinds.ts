/* ─── Boosthis: what KIND of outside service a call went to (Node) ─────────
 *
 * WHY THIS EXISTS. An AI-built app leans on a handful of outside services for
 * the things a visitor notices most, and until now every one of them arrived
 * as the same blurred figure: some outbound calls happened, some were slow.
 * "Sign-in is what is slow, and it has been getting worse for a week" is a
 * sentence a founder can act on; "outbound calls are slow" is not.
 *
 * THE PRIVACY CONTRACT, AND THE WHOLE REASON THIS FILE IS SHAPED THIS WAY.
 * Nothing derived here comes from the CONTENT of an address. A hostname is
 * matched against the closed table below, the matched INPUT IS THROWN AWAY,
 * and one of OUR OWN six constant words is emitted in its place. There is no
 * code path that copies a byte of a host, a path, a query string, a header or
 * a payload into the value that leaves. A host we do not recognise becomes
 * `other` — a visible group of its own, never folded into a known kind and
 * never guessed at.
 *
 * Because the vocabulary is closed, the server can validate it against the
 * SAME closed vocabulary (mirrored in artifacts/api-server/src/lib/pii.ts and
 * locked by a two-way parity test, exactly as the browser kit's call-group
 * labels already are). An open regex would wave `api.example.com` through; a
 * closed set cannot.
 *
 * WHAT IS DELIBERATELY NOT HERE.
 *   • Hosted databases (Supabase, Firebase, Neon, Turso …) are classified as
 *     DATABASE work upstream of this table and never reach it. Their reading
 *     is the `dbWork` axis and moving them here would report one wait twice.
 *   • AI providers are classified as AI work upstream too, for the same
 *     reason: their reading is the `aiCalls` axis.
 *   • Boosthis's own upload endpoint is excluded before any classification
 *     runs, so our flushes can never be reported as the customer's traffic.
 *
 * A JUDGEMENT WE REFUSE TO MAKE. This names the KIND of thing an app leans on.
 * It never names the vendor on any surface, never ranks one provider against
 * another, and never publishes a reliability claim about somebody else's
 * service. The vendor names below exist only so a hostname can be turned into
 * one of our six words and forgotten.
 */

/**
 * Every kind word this kit can ever emit. CLOSED SET — mirrored in the
 * server's ingest guard, which rejects anything outside it and drops the whole
 * row rather than rewriting it.
 *
 * Order is documentation, not a wire contract: the WORD travels, never a
 * position, so this list may be reordered or extended without breaking a
 * reading already stored.
 */
export const DEPENDENCY_KINDS = [
  /** Signing a visitor in. First thing every visitor does, and in front of
   *  every session — which is why it gets its own place on every surface. */
  "signin",
  /** Files and images: uploads, downloads, transformation, media delivery.
   *  Usually the slowest thing one of these apps does. */
  "storage",
  /** Taking money. The one path where a failure costs the founder money. */
  "payments",
  /** Email, SMS, push and chat delivery. Failures here are normally
   *  discovered by a customer complaining. */
  "messaging",
  /** Search over stored knowledge — the vector/index services an AI app asks
   *  before it answers. Behaves like a database, hides behind a web call. */
  "search",
  /** A destination this kit does not recognise. Its OWN visible group, so an
   *  unknown dependency is never quietly folded into a known kind. */
  "other",
] as const;

export type DependencyKind = (typeof DEPENDENCY_KINDS)[number];

/** The kinds that are a recognised service, i.e. everything but the honest
 *  "we do not know what this is" bucket. */
export const KNOWN_DEPENDENCY_KINDS: readonly DependencyKind[] =
  DEPENDENCY_KINDS.filter((k) => k !== "other");

/**
 * One recognition rule. `domain` is a vendor-owned domain matched against the
 * bare hostname the outbound observer already normalised (no scheme, no
 * userinfo, no port, no path) — and matched on a LABEL BOUNDARY: the host must
 * BE that domain or sit under it. A plain "ends with" test would read
 * notclerk.com as a sign-in service and evil-uploadthing.com as storage, which
 * would put a stranger's traffic under a trusted service's name and hide it
 * from the unrecognised group where it belongs. `prefix`, when present, must
 * ALSO match, which is how a vendor that puts the product in the first label
 * and the account in the middle (AWS) is recognised without claiming every
 * host at that vendor.
 *
 * Every entry is a vendor-owned DATA-PLANE name. A generic API host is
 * deliberately absent: mistaking an ordinary API for a payment provider would
 * put real traffic in a reading about money, which is the exact confusion this
 * table exists to end.
 */
interface KindRule {
  readonly domain: string;
  readonly prefix?: string;
  /** An inner label that must ALSO appear. Needed where the vendor puts the
   *  customer's own name FIRST and the product in the middle — the ordinary
   *  form of an S3 bucket URL — which neither a prefix nor a suffix can catch
   *  on its own. Matched with the dots included, so it can only ever match a
   *  whole label. */
  readonly infix?: string;
  readonly kind: DependencyKind;
}

/**
 * The maintained recognition list. It holds the KIND and nothing else: there
 * is no vendor identifier on the wire, no vendor column in the database and no
 * vendor name on any surface. A host that matches nothing here is `other`.
 */
export const KIND_RULES: readonly KindRule[] = [
  /* ── Signing in ──────────────────────────────────────────────────────── */
  { domain: "clerk.accounts.dev", kind: "signin" },
  { domain: "clerk.com", kind: "signin" },
  { domain: "auth0.com", kind: "signin" },
  { domain: "okta.com", kind: "signin" },
  { domain: "oktapreview.com", kind: "signin" },
  { domain: "okta-emea.com", kind: "signin" },
  { domain: "identitytoolkit.googleapis.com", kind: "signin" },
  { domain: "securetoken.googleapis.com", kind: "signin" },
  { domain: "accounts.google.com", kind: "signin" },
  { domain: "oauth2.googleapis.com", kind: "signin" },
  { domain: "login.microsoftonline.com", kind: "signin" },
  { domain: "appleid.apple.com", kind: "signin" },
  { domain: "amazoncognito.com", kind: "signin" },
  { domain: "amazonaws.com", prefix: "cognito-idp.", kind: "signin" },
  { domain: "amazonaws.com", prefix: "cognito-identity.", kind: "signin" },
  { domain: "workos.com", kind: "signin" },
  { domain: "authkit.app", kind: "signin" },
  { domain: "stytch.com", kind: "signin" },
  { domain: "supertokens.io", kind: "signin" },
  { domain: "supertokens.com", kind: "signin" },
  { domain: "propelauth.com", kind: "signin" },
  { domain: "kinde.com", kind: "signin" },
  { domain: "frontegg.com", kind: "signin" },
  { domain: "descope.com", kind: "signin" },
  { domain: "logto.app", kind: "signin" },
  { domain: "ory.sh", kind: "signin" },
  { domain: "api.magic.link", kind: "signin" },
  { domain: "keycloak.org", kind: "signin" },

  /* ── Files, images and uploads ───────────────────────────────────────── */
  { domain: "s3.amazonaws.com", kind: "storage" },
  { domain: "amazonaws.com", prefix: "s3.", kind: "storage" },
  { domain: "amazonaws.com", prefix: "s3-", kind: "storage" },
  // The ordinary regional bucket URL puts the customer's bucket first:
  // my-bucket.s3.eu-west-1.amazonaws.com. Without these two it reads as an
  // unrecognised destination, which is the single most common upload there is.
  { domain: "amazonaws.com", infix: ".s3.", kind: "storage" },
  { domain: "amazonaws.com", infix: ".s3-", kind: "storage" },
  { domain: "storage.googleapis.com", kind: "storage" },
  { domain: "firebasestorage.googleapis.com", kind: "storage" },
  { domain: "blob.core.windows.net", kind: "storage" },
  { domain: "r2.cloudflarestorage.com", kind: "storage" },
  { domain: "digitaloceanspaces.com", kind: "storage" },
  { domain: "backblazeb2.com", kind: "storage" },
  { domain: "wasabisys.com", kind: "storage" },
  { domain: "storage.bunnycdn.com", kind: "storage" },
  { domain: "cloudinary.com", kind: "storage" },
  { domain: "imagekit.io", kind: "storage" },
  { domain: "uploadthing.com", kind: "storage" },
  { domain: "uploadcare.com", kind: "storage" },
  { domain: "ucarecdn.com", kind: "storage" },
  { domain: "filestackapi.com", kind: "storage" },
  { domain: "bytescale.com", kind: "storage" },
  { domain: "mux.com", kind: "storage" },
  { domain: "transloadit.com", kind: "storage" },

  /* ── Taking money ────────────────────────────────────────────────────── */
  { domain: "stripe.com", kind: "payments" },
  { domain: "paypal.com", kind: "payments" },
  { domain: "adyen.com", kind: "payments" },
  { domain: "checkout.com", kind: "payments" },
  { domain: "razorpay.com", kind: "payments" },
  { domain: "paddle.com", kind: "payments" },
  { domain: "squareup.com", kind: "payments" },
  { domain: "braintreegateway.com", kind: "payments" },
  { domain: "lemonsqueezy.com", kind: "payments" },
  { domain: "mollie.com", kind: "payments" },
  { domain: "paystack.co", kind: "payments" },
  { domain: "flutterwave.com", kind: "payments" },
  { domain: "moyasar.com", kind: "payments" },
  { domain: "tap.company", kind: "payments" },
  { domain: "whop.com", kind: "payments" },
  { domain: "revenuecat.com", kind: "payments" },

  /* ── Reaching a customer ─────────────────────────────────────────────── */
  { domain: "resend.com", kind: "messaging" },
  { domain: "sendgrid.com", kind: "messaging" },
  { domain: "mailgun.net", kind: "messaging" },
  { domain: "mailgun.org", kind: "messaging" },
  { domain: "postmarkapp.com", kind: "messaging" },
  { domain: "mailjet.com", kind: "messaging" },
  { domain: "mailchimp.com", kind: "messaging" },
  { domain: "brevo.com", kind: "messaging" },
  { domain: "sendinblue.com", kind: "messaging" },
  { domain: "amazonaws.com", prefix: "email.", kind: "messaging" },
  { domain: "twilio.com", kind: "messaging" },
  { domain: "vonage.com", kind: "messaging" },
  { domain: "nexmo.com", kind: "messaging" },
  { domain: "unifonic.com", kind: "messaging" },
  { domain: "msg91.com", kind: "messaging" },
  { domain: "api.telegram.org", kind: "messaging" },
  { domain: "slack.com", kind: "messaging" },
  { domain: "discord.com", kind: "messaging" },
  { domain: "discordapp.com", kind: "messaging" },
  { domain: "fcm.googleapis.com", kind: "messaging" },
  { domain: "onesignal.com", kind: "messaging" },
  { domain: "exp.host", kind: "messaging" },
  { domain: "pushover.net", kind: "messaging" },
  { domain: "knock.app", kind: "messaging" },
  { domain: "courier.com", kind: "messaging" },

  /* ── Searching stored knowledge ──────────────────────────────────────── */
  { domain: "pinecone.io", kind: "search" },
  { domain: "weaviate.network", kind: "search" },
  { domain: "weaviate.cloud", kind: "search" },
  { domain: "qdrant.io", kind: "search" },
  { domain: "qdrant.tech", kind: "search" },
  { domain: "zillizcloud.com", kind: "search" },
  { domain: "zilliz.com", kind: "search" },
  { domain: "trychroma.com", kind: "search" },
  { domain: "turbopuffer.com", kind: "search" },
  { domain: "vectara.io", kind: "search" },
  { domain: "algolia.net", kind: "search" },
  { domain: "algolianet.com", kind: "search" },
  { domain: "algolia.io", kind: "search" },
  { domain: "typesense.net", kind: "search" },
  { domain: "meilisearch.io", kind: "search" },
  { domain: "meilisearch.com", kind: "search" },
  { domain: "elastic-cloud.com", kind: "search" },
];

// A label that is a bare ADDRESS rather than one of our own words: a dotted
// hostname ("api.stripe.com") or an IPv4 literal ("10.0.0.5"). The retry-storm
// detector names the host it saw hammered, which is exactly right for the
// developer's own screen inside their own process — and exactly wrong on the
// wire, because our published privacy claim says a hostname never reaches us.
// Anchored, dot-bearing and whitespace-free, so our own code-defined finding
// names ("responses", "event loop", "GET /pay") are never mistaken for one.
const BARE_ADDRESS_RE =
  /^[a-z0-9](?:[a-z0-9-]*[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9-]*[a-z0-9])?)+$/i;

/** True when a label is a bare outbound address — a hostname or an IPv4 —
 *  rather than a code-defined word. Used at the transmit boundary: an address
 *  is replaced by the closed dependency-kind vocabulary above, never uploaded.
 *
 *  Mirrors `looks_like_address` in `lib/boosthis-py/boosthis/pii.py`. */
export function looksLikeAddress(label: string): boolean {
  return BARE_ADDRESS_RE.test(label);
}

/**
 * Which kind of outside service this hostname is, or `other` when the table
 * does not recognise it.
 *
 * Pure, total and cheap — it runs on every outbound call. The hostname is read
 * and dropped; only the returned constant is ever kept. Never throws.
 */
export function dependencyKindFor(host: unknown): DependencyKind {
  try {
    const h = typeof host === "string" ? host.toLowerCase() : "";
    if (!h) return "other";
    for (const rule of KIND_RULES) {
      // Label-boundary match ONLY: the host either IS the vendor's domain or
      // sits under it. Never a bare "ends with", which would hand a lookalike
      // domain a trusted service's name.
      const domainHit = h === rule.domain || h.endsWith("." + rule.domain);
      if (!domainHit) continue;
      if (rule.prefix && !h.startsWith(rule.prefix)) continue;
      if (rule.infix && !h.includes(rule.infix)) continue;
      return rule.kind;
    }
    return "other";
  } catch {
    return "other";
  }
}

/**
 * SIGN-IN LIBRARIES THAT RUN INSIDE THE APP, AND WHY THEY NEED THEIR OWN
 * ANSWER.
 *
 * Several of the most popular ways to sign a visitor in make NO outbound call
 * at all: the library runs in the app's own process and talks only to the
 * app's own database. Classifying by destination misses them completely — and
 * telling a founder their app has no sign-in when it plainly has one would be
 * far worse than saying nothing.
 *
 * So we recognise them another way, exactly as the database meter already
 * recognises a driver it cannot watch: by looking for the library in the
 * module cache the host ALREADY filled. This kit never imports one of these,
 * never resolves one into existence, and reads nothing but the presence of the
 * name. The finding is reported as a plain sentence — sign-in happens inside
 * your app, so there is no outside call to time — never as an absence.
 *
 * Deliberately NOT here: a plain session or cookie library, and a password
 * hashing library, on their own. A session store is not proof that the app
 * signs anybody in, and a hashing function is not proof either — plenty of
 * apps hash something without having a sign-in. Claiming sign-in on that
 * evidence would be exactly the guess this whole file refuses to make. Every
 * name below exists for one purpose only: signing a person in.
 */
export const IN_APP_SIGNIN_PACKAGES: readonly string[] = [
  "next-auth",
  "@auth/core",
  "@auth/sveltekit",
  "@auth/express",
  "better-auth",
  "lucia",
  "@lucia-auth/adapter-drizzle",
  "passport",
  "passport-local",
  "openid-client",
  "remix-auth",
  "@nestjs/passport",
  "grant",
  "supertokens-node",
];
