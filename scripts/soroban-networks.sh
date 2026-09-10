#!/usr/bin/env bash
# Soroban network settings with --network switch flag support.
# Source this file: source scripts/soroban-networks.sh && resolve_network testnet
SOROBAN_RPC_TESTNET="${SOROBAN_RPC_TESTNET:-https://soroban-testnet.stellar.org}"
SOROBAN_RPC_MAINNET="${SOROBAN_RPC_MAINNET:-https://soroban.stellar.org}"
SOROBAN_TESTNET_PASSPHRASE="${SOROBAN_TESTNET_PASSPHRASE:-Test SDF Network ; September 2015}"
SOROBAN_MAINNET_PASSPHRASE="${SOROBAN_MAINNET_PASSPHRASE:-Public Global Stellar Network ; September 2015}"

resolve_network() {
  local net="${1:-${SOROBAN_NETWORK:-testnet}}"
  case "$net" in
    testnet)
      SOROBAN_RPC_URL="$SOROBAN_RPC_TESTNET"
      SOROBAN_PASSPHRASE="$SOROBAN_TESTNET_PASSPHRASE"
      ;;
    mainnet)
      SOROBAN_RPC_URL="$SOROBAN_RPC_MAINNET"
      SOROBAN_PASSPHRASE="$SOROBAN_MAINNET_PASSPHRASE"
      ;;
    *)
      echo "Unknown network: $net (use testnet|mainnet)" >&2
      return 1
      ;;
  esac
  export SOROBAN_RPC_URL SOROBAN_PASSPHRASE SOROBAN_NETWORK="$net"
}
