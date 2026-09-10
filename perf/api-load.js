import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  vus: 50,
  duration: "2m",
  thresholds: {
    // Cached API must stay under 300ms p95 (PRD 1125)
    http_req_duration: ["p(95)<300"],
    http_req_failed: ["rate<0.01"],
  },
};

const BASE = __ENV.API_URL ?? "https://api.staging.stellariq.io";

export default function () {
  const r1 = http.get(`${BASE}/v1/prices?asset=XLM`);
  check(r1, { "prices 200": (r) => r.status === 200, "prices fast": (r) => r.timings.duration < 300 });
  const r2 = http.get(`${BASE}/v1/markets?limit=20`);
  check(r2, { "markets 200": (r) => r.status === 200 });
  sleep(1);
}
