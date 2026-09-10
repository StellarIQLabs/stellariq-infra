#!/usr/bin/env bash
# Deploy Soroban contracts to testnet / mainnet via stellar-cli.
# Usage: ./scripts/deploy-contracts.sh --network testnet --wasm-bucket <bucket>
set -euo pipefail

NETWORK="testnet"
WASM_BUCKET="${WASM_BUCKET:-}"
SOURCE_ACCOUNT="${SOURCE_ACCOUNT:-deployer}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --network) NETWORK="$2"; shift 2 ;;
    --wasm-bucket) WASM_BUCKET="$2"; shift 2 ;;
    --source) SOURCE_ACCOUNT="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

# shellcheck source=scripts/soroban-networks.sh
source "$(dirname "$0")/soroban-networks.sh"
resolve_network "$NETWORK"

echo "Deploying contracts to $NETWORK (RPC: $SOROBAN_RPC_URL)"

for wasm in artifacts/*.wasm; do
  [ -e "$wasm" ] || { echo "No wasm artifacts in artifacts/. Build first."; exit 1; }
  name="$(basename "$wasm" .wasm)"
  echo "-> $name"
  stellar contract deploy \
    --wasm "$wasm" \
    --source-account "$SOURCE_ACCOUNT" \
    --rpc-url "$SOROBAN_RPC_URL" \
    --network-passphrase "$SOROBAN_PASSPHRASE"
done

if [[ -n "$WASM_BUCKET" ]]; then
  echo "Uploading artifacts to s3://$WASM_BUCKET/$NETWORK/"
  aws s3 sync artifacts/ "s3://$WASM_BUCKET/$NETWORK/" --exclude "*" --include "*.wasm"
fi

echo "Done."
