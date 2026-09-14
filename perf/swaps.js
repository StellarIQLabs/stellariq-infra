import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  vus: 30,
  duration: "2m",
  thresholds: {
    // Swap quote path: routing-engine must stay under 1s p95 (PRD 1124)
    http_req_duration: ["p(95)<1000"],
    http_req_failed: ["rate<0.01"],
  },
};

const BASE = __ENV.API_URL ?? "https://api.staging.stellariq.io";

const PAIRS = [
  { from: "XLM", to: "USDC", amount: "1000" },
  { from: "XLM", to: "BTC", amount: "500" },
  { from: "USDC", to: "XLM", amount: "250" },
  { from: "USDT", to: "XLM", amount: "100" },
  { from: "XLM", to: "ETH", amount: "2000" },
  { from: "BTC", to: "USDC", amount: "10" },
  { from: "ETH", to: "XLM", amount: "500" },
  { from: "USDC", to: "BTC", amount: "500" },
];

export default function () {
  const pair = PAIRS[Math.floor(Math.random() * PAIRS.length)];
  const url = `${BASE}/v1/quotes?from=${pair.from}&to=${pair.to}&amount=${pair.amount}`;
  const r = http.get(url);

  const ok = r.status === 200 && r.timings.duration < 1000;
  check(r, {
    "quote 200": (res) => res.status === 200,
    "quote under 1s": (res) => res.timings.duration < 1000,
  });

  if (ok) {
    const body = JSON.parse(r.body);
    check(body, {
      "has routes": (b) => Array.isArray(b.routes) && b.routes.length > 0,
      "has best route": (b) => b.routes?.[0]?.output != null,
    });
  }

  sleep(1);
}
