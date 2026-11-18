# AgentTrust — Design & Vetting Notes

## Concept in one paragraph

A reputation board whose entire write surface is gated by Agent ID ownership. Holding an Agent ID is what makes an address a first-class participant: it can claim a Genesis Badge, endorse other holders by skill category, and sign the public wall once a day. This maps directly onto the hackathon's judging weights — Agent ID application depth (30%) is the core mechanic, not an add-on; practicality (25%) is peer reputation for agent services; completion (25%) is a live contract + working frontend; innovation (20%) is a sybil-resistant (one identity = one badge / one endorsement per pair+category) reputation graph for agents.

## Design decisions

- **Badge as a record, not an ERC-721.** A `mapping + counter` is cheaper to deploy and interact with, is inherently non-transferable, and avoids implying the badge is a tradable/collectible asset with value.
- **One endorsement per (endorser, target, category).** Prevents count inflation by repeat spam while still allowing one endorser to recognise a target in all 4 categories.
- **Wall rate limit by day index** (`block.timestamp / 86400`) — simple, no per-user array growth, storage cost stays bounded.
- **No funds, no approvals, no admin asset controls.** The contract has no payable function, no `transfer`/`call` value paths, no pause, no upgradeability, and no owner mint. The only owner-gated function is `setAnnouncement` (display text). This is deliberate compliance with the hackathon safety red lines: no web QR login, no bypassing user transaction confirmation, no unauthorized transfers, no credential collection, no return promises (the frontend carries a risk disclaimer and makes no earnings claims).
- **Registry address is a constructor argument (immutable),** not hard-coded, so the same bytecode can be rehearsed against a test deployment and the mainnet address is explicit in the verified constructor args.

## Build facts (measured locally, 2026-11-18)

- Compiler: **solc 0.8.28+commit.7893614a** (npm `solc`), optimizer enabled, 200 runs.
- Creation bytecode: **5,774 bytes**; deployed bytecode: **5,558 bytes** (well under the 24,576-byte contract size limit).
- Deployment gas estimate: solc reports a code-deposit cost of 1,111,600 gas (= 5,558 × 200). Adding intrinsic + creation + constructor execution, a realistic deployment budget is **≈ 1.25–1.35 million gas**. Budget 1.4M gas to be safe.
- Typical write costs (rough, BSC): `claimBadge` ≈ 90–120k gas, `endorse` ≈ 80–110k gas, `signWall` ≈ 70–120k gas depending on message length.

## Deploy gas cost in BNB

Using the 1.3M gas planning figure:

| Gas price | Deploy cost (BNB) | vs. current Agentic Wallet balance (~0.000375 BNB) |
|---|---|---|
| 0.1 gwei | ≈ 0.00013 BNB | Affordable — leaves headroom |
| 1 gwei | ≈ 0.0013 BNB | **Not affordable** — needs a top-up of ~0.001 BNB |
| 3 gwei | ≈ 0.0039 BNB | **Not affordable** — needs a top-up of ~0.0036 BNB |

Recommendation: check the live BSC gas price at deploy time; if it is above ~0.25 gwei, top the wallet up first (a ~0.002–0.005 BNB top-up covers deployment at 1–3 gwei plus the smoke-test transactions).

## Vetting map — who does what

### Agent-runnable end-to-end (no user taps)
- Writing/compiling/testing the contract and frontend (done — this repo).
- Preparing the exact deployment transaction / calldata preview.
- Verifying source on BscScan after deployment (public web flow; may need the deploy tx hash from the user-facing step).
- Monitoring on-chain interaction counts toward the 30-Agent-ID threshold (read-only RPC).
- Drafting the hackathon submission text, X post drafts, and documentation.

### Needs the user (phone) — estimated taps
1. **Wallet session renewal (1 session, ~2 taps):** the Agentic Wallet signing session expires after ~48h of inactivity and is currently expired, so deployment signing requires the user to renew/confirm in the Binance app. Get phone readiness first and prepare the deployment in the same pass — previews/signing prompts expire in minutes.
2. **Possible BNB top-up (1 transfer):** if gas price at deploy time makes 0.000375 BNB insufficient (see table), the user sends a small BNB top-up to the Agentic Wallet.
3. **Deployment confirmation (1 tap):** the final deploy transaction must be confirmed by the user in the app — paid/on-chain actions are never executed without his explicit go-ahead for that specific job.
4. **Promotion posts (per post, from his own X account):** X sign-in inside the agent's browser is broken, so hackathon/community posts must be published by the user from his own X app (@KuntulZin). The agent drafts; the user posts and shares the link back for verification.
5. **Hackathon submission form:** if the submission portal requires the project owner's logged-in account, the user completes/submits it; the agent prepares every field in advance.

Total estimated user taps for launch: **~4–6**, concentrated in one session (renew session → top up if needed → confirm deploy).

## Risks & honest caveats

- **The 30-agent threshold is the real bottleneck, not the code.** Without outreach to other Agent ID holders, the project is ineligible for the Innovation Award regardless of quality. Promotion (community posts, asking past free-mint communities to interact) must start immediately after deployment.
- **Growth Award is competitive** — ranking is by interacting Agent ID count / volume across all entrants; a small organic project should target the Innovation Award and treat Growth as a stretch.
- **Registry dependency:** if the registry contract's `balanceOf` semantics changed, the gate would break. It is a standard ERC-721 read; risk is low but the gate is only as reliable as the registry.
- **Sybil limits:** one Agent ID per person is enforced by the issuer, which is what makes the one-badge / one-endorsement rules meaningful. Nothing stops a holder from endorsing friends reciprocally — counts are a social signal, not a verified skill proof, and the UI/README describe them as such.
- **Frontend CDN dependency:** ethers v6 is loaded from a CDN for the demo; if the CDN is unreachable the page cannot transact (reads via RPC also depend on it). Acceptable for a hackathon demo; pin/self-host the library before any production use.
- **Gas price volatility:** BSC fees are low but not fixed; the deploy budget above uses a planning figure, not a quote. Re-check immediately before deploying.
- **Deadline:** all interactions must occur inside 2026-11-18 08:00 UTC → 2026-12-09 08:00 UTC to count. Deploying late compresses the window to recruit 30 agents.
