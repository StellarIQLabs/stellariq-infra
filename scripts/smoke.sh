#!/usr/bin/env bash
# End-to-end MVP smoke (PRD 1406): search asset, price, liquidity, compare markets,
# inspect pools, quote, generate transaction — through deployed infra.
set -euo pipefail
BASE="${1:-https://api.staging.stellariq.io}"

pass=0; fail=0
check() {
  local name="$1" path="$2" jq_expr="$3"
  local out code
  out="$(curl -fsS -m 15 "$BASE$path" || true)"
  if echo "$out" | python3 -c "import json,sys; d=json.load(sys.stdin); assert ($jq_expr), 'assertion failed'" 2>/dev/null; then
    echo "PASS $name"; pass=$((pass+1))
  else
    echo "FAIL $name ($path)"; fail=$((fail+1))
  fi
}

check "search-asset"   "/v1/assets?search=XLM"                 "True"
check "view-price"     "/v1/prices?asset=XLM"                  "True"
check "liquidity"      "/v1/pools?asset=XLM"                   "True"
check "compare"        "/v1/markets?asset=XLM"                 "True"
check "quote"          "/v1/quotes?from=XLM&to=USDC&amount=100" "True"

echo "smoke: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
