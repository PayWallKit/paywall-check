#!/usr/bin/env bash
# paywall-check.sh: 60-second smoke test for the Stripe paywall bugs AI agents write most.
# Usage: ./paywall-check.sh https://yourapp.com /api/webhooks/stripe /success [path/to/client/build]
# Read-only: it sends one unsigned POST to YOUR webhook and one GET to YOUR success page. Run it only on apps you own.
set -u
BASE="${1:?base url, e.g. https://yourapp.com}"; HOOK="${2:-/api/webhooks/stripe}"; SUCCESS="${3:-/success}"; BUILD="${4:-}"
pass(){ printf '  \033[32mPASS\033[0m %s\n' "$1"; }; fail(){ printf '  \033[31mFAIL\033[0m %s\n' "$1"; FAILS=$((FAILS+1)); }; FAILS=0
echo "1. Unsigned webhook must be rejected"
code=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$BASE$HOOK" -H 'content-type: application/json' \
  -d '{"id":"evt_fake","type":"checkout.session.completed","data":{"object":{"id":"cs_fake","payment_status":"paid"}}}')
if [[ "$code" =~ ^2 ]]; then fail "webhook returned $code to an unsigned fake event (anyone can forge payments)"; elif [ "$code" = "404" ] || [ "$code" = "000" ]; then printf "  WARN webhook path returned %s; check the URL\n" "$code"; else pass "webhook returned $code"; fi
echo "2. Success page must not grant access on its own"
code=$(curl -s -o /tmp/pc_success -w '%{http_code}' "$BASE$SUCCESS?session_id=cs_fake")
if grep -qiE 'welcome to pro|you.re now pro|upgraded|access granted' /tmp/pc_success; then fail "success page with a fake session_id says you're upgraded"; else pass "no upgrade text with a fake session_id (HTTP $code); still confirm by checking your DB"; fi
if [ -n "$BUILD" ]; then
  echo "3. No secrets in the client bundle ($BUILD)"
  if grep -rqE 'sk_(live|test)_[A-Za-z0-9]{10,}|whsec_[A-Za-z0-9]{10,}|service_role' "$BUILD"; then fail "secret-looking string found in client build"; else pass "no sk_/whsec_/service_role strings"; fi
fi
echo; echo "Not covered here (do these by hand): refunds/cancellations revoking access, duplicate events, client-chosen prices, RLS on billing tables."
exit $FAILS
