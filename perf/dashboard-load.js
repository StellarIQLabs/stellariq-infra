import http from "k6/http";
import { check } from "k6";

export const options = {
  vus: 20,
  duration: "2m",
  thresholds: {
    // Dashboard initial load < 2s; quote path covered by routing-engine SLO < 1s
    http_req_duration: ["p(95)<2000"],
    http_req_failed: ["rate<0.01"],
  },
};

const WEB = __ENV.WEB_URL ?? "https://app.staging.stellariq.io";

export default function () {
  const r = http.get(`${WEB}/`);
  check(r, { "web 200": (x) => x.status === 200 });
}
