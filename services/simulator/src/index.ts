import express from "express";

// Transaction simulation helper used by the API before submission (PRD 1144).
// Simulates a Stellar/Soroban transaction against the configured RPC endpoint
// without submitting, returning resource estimates + auth requirements.
const app = express();
app.use(express.json());

const RPC_URL = process.env.SOROBAN_RPC_URL ?? "https://soroban-testnet.stellar.org";

app.get("/health", (_req, res) => {
  res.json({ status: "ok", service: "simulator" });
});

app.post("/v1/simulate", async (req, res) => {
  const { transactionXdr, network = "testnet" } = req.body ?? {};
  if (typeof transactionXdr !== "string" || transactionXdr.length === 0) {
    res.status(400).json({ error: "transactionXdr is required" });
    return;
  }
  try {
    const rpcRes = await fetch(RPC_URL, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        jsonrpc: "2.0",
        id: 1,
        method: "simulateTransaction",
        params: { transaction: transactionXdr },
      }),
    });
    const data = (await rpcRes.json()) as unknown;
    res.json({ network, simulated: true, result: data });
  } catch (err) {
    res.status(502).json({
      error: "simulation_failed",
      message: err instanceof Error ? err.message : String(err),
    });
  }
});

const port = Number(process.env.PORT ?? 4301);
app.listen(port, () => {
  console.log(JSON.stringify({ msg: "simulator listening", port }));
});
