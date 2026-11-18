# AgentTrust — Deployment Record (BSC mainnet)

Deployed: **2026-11-18 ~18:10 WIB** (block 134,300,557)

## Contract

- **AgentTrust address:** `0x9F5b0726197390138d9ebE1e7B873FD5B4528a0c`
- **Deploy tx:** `0xcc8e06e87b1ec59c8fd953b8fe6b6a3a9c0591f7e2d0aedc71d38e008c0abe48`
- **Deployer / owner:** `0x2CFc756D128dde00E3168F876aF91f02e1A18562` (user's Agentic Wallet, Agent ID dudukuyz.ai)
- **Agent ID registry (constructor arg):** `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`
- **Deploy method:** deterministic deployment proxy (EIP-2470) `0x4e59b44847b379578588920cA78FbF26c0B4956C`, CREATE2, salt = 0x0. baw CLI cannot send a contract-creation tx (`--to` is required), so the proxy was used. Calldata = 32 zero bytes (salt) + creation bytecode + ABI-encoded constructor args (registry, owner).
- **Fee:** 0.00013373 BNB (gasUsed 1,283,320 × effective gas price 0.1042 gwei)
- **Wallet BNB after deploy:** 0.00020141 BNB

## On-chain verification (read 2026-11-18 ~18:12 WIB)

- Code at address: 5,558 bytes, matches build's deployed bytecode except for the immutable `agentIdRegistry` slots, which on-chain contain `0x60B9...022F` (expected — solc output has zeros there).
- `owner()` = user's wallet ✓
- `agentIdRegistry()` = `0x60B9...022F` ✓
- `isAgentIdHolder(user)` = true ✓
- `totalAgentsJoined()` = 0, `totalBadges()` = 0, `wallCount()` = 0 (fresh contract, no interactions yet)
- Frontend `site/index.html` CONFIG.contractAddress updated to the deployed address.

## Build

- Compiler solc 0.8.28, optimizer on, 200 runs. Creation bytecode 5,849 bytes; constructor changed before deploy to `(address registry, address initialOwner)` so the owner is the user's wallet (a factory deployment would otherwise make the factory `msg.sender` / owner).

## Failed first attempt (no-op, honest record)

- Tx `0x32ec8054fb6c2f30977e0ec511095085bb593618d01b021f52b4c57b6c9c6e16` was a contract-call to the zero address with the creation bytecode as inputData. In the EVM, `to = 0x000...0` is a call to the zero address, NOT a contract creation — the tx succeeded doing nothing (gasUsed 247,390, fee ~0.0000161 BNB). No contract was created. Lesson: baw `contract-call` cannot deploy directly; the EIP-2470 proxy route above is the working path.
- Total deploy-related spend: ~0.0001498 BNB (failed attempt + successful deploy).

## Still to do (NOT in this task)

- BscScan source verification + open-source the contract.
- Publish the frontend (site/index.html) somewhere public.
- Submit to the Binance Agent ID Hackathon (deadline 2026-12-09 08:00 UTC) — needs ≥30 distinct Agent ID addresses interacting during the submission period.
- Promotion from the user's own X (@KuntulZin).
