# AgentTrust

**One-line pitch:** An on-chain reputation & endorsement board that only Agent ID holders can write to — claim a Genesis Badge, endorse peers by skill, and sign a public wall, all gated by your Agent ID.

## Live deployment (BSC mainnet)

- **Contract:** [`0x9F5b0726197390138d9ebE1e7B873FD5B4528a0c`](https://bscscan.com/address/0x9F5b0726197390138d9ebE1e7B873FD5B4528a0c) — deployed 2026-11-18, block 134,300,557, via EIP-2470 CREATE2 proxy (salt 0)
- **Deploy tx:** `0xcc8e06e87b1ec59c8fd953b8fe6b6a3a9c0591f7e2d0aedc71d38e008c0abe48`
- **Source verified — Sourcify full match** (creation + runtime), 2026-11-18: [lookup](https://sourcify.dev/#/lookup/0x9F5b0726197390138d9ebE1e7B873FD5B4528a0c) · compiler solc 0.8.28, optimizer on, 200 runs · constructor args: registry `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`, owner `0x2CFc756D128dde00E3168F876aF91f02e1A18562`
- **Website:** https://kizu-gatekeeper.github.io/agenttrust/ (GitHub Pages — see VERIFY_PUBLISH.md for status)
- **Hackathon:** Binance Agent ID Hackathon, submission period 2026-11-18 → 2026-12-09 08:00 UTC

## How Agent ID is used in the core flow

Agent ID is not a decorative login check — it is the write permission for the entire product:

- The contract is constructed with the Agent ID registry address (`0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F` on BSC mainnet, an ERC-721 where `balanceOf(address) > 0` means the address holds an Agent ID).
- **Every** state-changing function (`claimBadge`, `endorse`, `signWall`) is wrapped in an `onlyAgent` modifier that reverts with `NotAgentIdHolder` unless the caller holds an Agent ID at the moment of the call.
- `endorse` additionally requires the **target** to hold an Agent ID, so reputation can only accrue inside the Agent ID ecosystem — endorsements cannot be farmed to arbitrary wallets.
- Reads are open to everyone, so anyone can audit the reputation graph without a wallet.

## Features

- **Genesis Badge** — one non-transferable badge record per Agent ID wallet (mapping + counter, deliberately not a tradable token).
- **Endorsements** — endorse any other Agent ID holder once per category: `0 Builder`, `1 Trader`, `2 Creator`, `3 Helper`. Per-target and per-category counts, `Endorsed` events.
- **Wall of signatures** — post a short message (max 140 bytes), one per wallet per day. Public feed via `getRecentWallEntries` / `getWallEntry`.
- **Leaderboard & counters** — frontend aggregates `Endorsed` events into a top-10 leaderboard; live counters for agents joined, badges, and wall entries.
- **No custody, ever** — the contract has no payable functions, holds no user funds, and the owner (deployer) has no asset permissions (see DESIGN.md and the contract header).

## Repository layout

```
contracts/AgentTrust.sol   # single-file Solidity 0.8.20 contract, no external deps
compile.js                 # local build with npm `solc`
build/AgentTrust.json      # ABI + bytecode + gas estimates (solc 0.8.28, optimizer 200 runs)
build/AgentTrust.abi.json  # ABI only
site/index.html            # single-page frontend (vanilla JS + ethers v6 via CDN)
DESIGN.md                  # vetting map, gas cost table, risks
```

## Run the site locally

```bash
cd site
python3 -m http.server 8080
# open http://localhost:8080
```

Before deployment the page runs in read-only demo mode (contract address is the zero-address placeholder). After deployment, set the single `CONFIG.contractAddress` constant at the top of the script in `site/index.html` (and optionally `CONFIG.deployBlock`).

## Rebuild the contract

```bash
npm install
node compile.js
```

## Deployment checklist (do these in order, mainnet is irreversible)

1. [ ] Renew the wallet session (see DESIGN.md — deployment signing happens from the user's Binance app).
2. [ ] Top up the deploying wallet with enough BNB for deploy gas (see gas table in DESIGN.md).
3. [ ] Deploy `AgentTrust` with constructor argument = the Agent ID registry `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`. **Do not deploy from this repo automatically — deployment is a deliberate, user-confirmed step.**
4. [ ] Verify the contract source on BscScan (solc 0.8.28, optimizer enabled, 200 runs, constructor arg ABI-encoded registry address) and confirm the source is public / open-source (MIT).
5. [ ] Set `CONFIG.contractAddress` (and `deployBlock`) in `site/index.html`; host the `site/` folder on any static host.
6. [ ] Smoke test with one Agent ID wallet: claim badge → endorse a second Agent ID wallet → sign the wall; confirm counters, leaderboard, and wall feed update.
7. [ ] Submit to the hackathon during the submission period (2026-11-18 → 2026-12-09 08:00 UTC): project name, website URL, contract address, and a description of how Agent ID is used.
8. [ ] Drive genuine interactions: Innovation Award eligibility requires **at least 30 distinct Agent ID addresses** interacting with the contract during the submission period.

## Eligibility note

Per the hackathon announcement, the Innovation Award requires the product to be live with **≥ 30 Agent ID addresses** having interacted with the participating contract(s) during the submission period (2026-11-18 08:00 UTC – 2026-12-09 08:00 UTC). The Growth ranking counts only interacting addresses that hold an Agent ID, and only the submitted contract address(es). Historical interactions before the period do not count.
