# AgentCheck — Agent ID Daily Check-In & Reputation Registry

A daily check-in and reputation registry for the **Agent ID** ecosystem on BNB
Chain, built for the Binance Wallet × BNB Chain **Agent ID Hackathon**
(submission deadline: **9 Dec 2026, 08:00 UTC**).

Only Agent ID holders can check in — once per UTC day — building on-chain
streaks that any other dApp can read through public view functions. AgentCheck
is a composable "proof of active agent" primitive: no owner, no admin, no
token, no fees, no approvals.

See **CONCEPT.md** for the full submission concept (problem, Agent ID
integration, judging-criteria mapping, growth plan, compliance checklist).

## What's in this repo

| Path | What it is |
|---|---|
| `CONCEPT.md` | Submission-grade concept document |
| `src/AgentCheckIn.sol` | The contract (Solidity ^0.8.20, zero dependencies, ~1.5 KB runtime) |
| `test/AgentCheckIn.t.sol` | Foundry test suite (10 tests) |
| `test/MockAgentID.sol` | Minimal mock Agent ID ERC-721 used by the tests |
| `frontend/index.html` | Single-file frontend (vanilla JS, EIP-1193, hand-rolled ABI calls) |
| `foundry.toml` | Foundry config (solc 0.8.26, optimizer 200 runs) |

## Test results

```
forge test  →  10 passed, 0 failed, 0 skipped
```

Covered: non-holder check-in reverts; holder check-in registers and emits
events; second check-in on the same UTC day reverts; next-day check-in
increments the streak; a skipped day resets the streak to 1 (lifetime count
keeps growing); two holders count as two unique agents; all view functions
return correct values for known and unknown addresses.

Live sanity checks against the production Agent ID registry
(`0x60b9262456de011f7d15a54cdd8c48baaa8b022f`, read-only, 18 Nov 2026):

- `balanceOf(0xe1DB8E8aD894f9aE37194D8E70D1c375bD88D4f1)` = **1** (the project
  wallet holds its Agent ID, as expected) — confirmed via two public BSC RPCs.
- The registry does **not** implement ERC721Enumerable
  (`supportsInterface(0x780e9d63)` = false; `tokenOfOwnerByIndex` reverts) —
  noted in CONCEPT.md as a v2 design constraint.

## Status

| Step | State |
|---|---|
| Concept document | ✅ Done |
| Contract + tests (10/10 green) | ✅ Done |
| Frontend prototype (JS syntax-checked) | ✅ Done — **not** end-to-end testable until the contract is deployed |
| Deploy to BSC mainnet | ⏳ Awaiting user: BNB gas top-up + deploy confirmation |
| BscScan verification | ⏳ After deployment |
| Frontend contract address + hosting | ⏳ After deployment |
| Hackathon submission | ⏳ After deployment, before 9 Dec 2026 08:00 UTC |
| Drive ≥30 unique Agent ID interactions | ⏳ After submission (see CONCEPT.md §6) |

## Deployment runbook (for later — nothing here has been executed)

Prerequisites: a deployer wallet holding enough BNB for one small contract
deployment (the contract is ~1.5 KB; deployment is a single transaction), and
Foundry installed (`~/.foundry/bin`).

```bash
cd ~/workspace/agentid-hackathon
export PATH="$HOME/.foundry/bin:$PATH"

# 1. Compile
forge build

# 2. Deploy to BSC mainnet.
#    Constructor argument = production Agent ID registry (BNB Chain):
#    0x60b9262456de011f7d15a54cdd8c48baaa8b022f
forge create src/AgentCheckIn.sol:AgentCheckIn \
  --rpc-url https://bsc-dataseed.binance.org \
  --private-key <DEPLOYER_PRIVATE_KEY> \
  --constructor-args 0x60b9262456de011f7d15a54cdd8c48baaa8b022f

# 3. Verify the source on BscScan (needs a BscScan API key)
forge verify-contract <DEPLOYED_ADDRESS> src/AgentCheckIn.sol:AgentCheckIn \
  --chain-id 56 \
  --constructor-args $(cast abi-encode "constructor(address)" 0x60b9262456de011f7d15a54cdd8c48baaa8b022f) \
  --etherscan-api-key <BSCSCAN_API_KEY>

# 4. Sanity-check the deployment (read-only)
cast call <DEPLOYED_ADDRESS> "agentId()(address)" --rpc-url https://bsc-dataseed.binance.org
cast call <DEPLOYED_ADDRESS> "isAgent(address)(bool)" 0xe1DB8E8aD894f9aE37194D8E70D1c375bD88D4f1 \
  --rpc-url https://bsc-dataseed.binance.org   # expect: true
```

Then:

5. Put the deployed address into `frontend/index.html`
   (`AGENTCHECK_ADDRESS` at the top of the script) and host the page
   (any static host).
6. Do one real check-in from an Agent ID wallet and confirm the counters move.
7. Submit the project through the hackathon's official channel with: project
   name (**AgentCheck**), website (hosted frontend), contract address, and
   the Agent ID usage description from CONCEPT.md §3.
8. Run the growth plan (CONCEPT.md §6) to reach ≥30 unique Agent ID holders
   checking in during the submission period.

## License

MIT — see `LICENSE`. The contract source declares `SPDX-License-Identifier: MIT`.
