# paywall-check

A 60-second smoke test for the Stripe paywall bugs AI coding agents (Cursor, Claude Code, Lovable, Bolt, Replit) write most often:

1. **Unsigned webhook accepted.** One `curl` can fake "payment succeeded".
2. **Success page grants access.** Anyone who visits `/success` gets Pro.
3. **Secret keys in the client bundle.** `sk_live_`, `whsec_` or `service_role` shipped to the browser.

```bash
./paywall-check.sh https://yourapp.com /api/webhooks/stripe /success ./.next/static
```

Run it only against apps you own. It sends one unsigned POST and one GET; nothing else.

## Rules to paste into AGENTS.md / CLAUDE.md / .cursor/rules

```
- The webhook is the only writer of paid access. Success pages, redirects,
  client callbacks and query strings never grant access.
- Verify every webhook with stripe.webhooks.constructEvent(rawBody, signature,
  STRIPE_WEBHOOK_SECRET). Use the raw body; never parse JSON first.
  (Supabase Edge Functions / Deno: constructEventAsync + createSubtleCryptoProvider.)
- Idempotency: record event.id before handling; skip duplicates.
- The client sends a plan key, never a price, amount, quantity or user id.
- Gate on the server. UI checks are cosmetic.
- customer.subscription.deleted, charge.refunded and charge.dispute.created remove access.
```

## Want the full version?

Paywall Kit ($19) has the complete rules file, 9 prompts, type-checked Next.js + Supabase reference code (verified, idempotent webhook, portal, entitlements, RLS migration), a Stripe CLI test script for failure paths and retries, and a go-live checklist: https://paywall-kit.pages.dev

MIT licensed. Not affiliated with Stripe.
