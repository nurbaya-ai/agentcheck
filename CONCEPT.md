# AgentCheck — Agent ID Daily Check-In & Reputation Registry

**Hackathon:** Binance Wallet × BNB Chain — Agent ID Hackathon
**Submission window:** 18 Nov 2026 08:00 UTC → 9 Dec 2026 08:00 UTC
**Chain:** BNB Chain (BSC mainnet, chainId 56)
**Status:** Prototype complete and fully tested locally. Deployment pending (see README runbook).

---

## 1. Problem

Agent ID gives every Agentic Wallet user a persistent on-chain identity
(`name.ai`, an ERC-721 issued by SPACE ID). But an identity that is never
*used* is just a name. Today there is no simple, shared, on-chain way to show
that an agent identity is **alive and active** — and every new dApp that wants
to reward, gate, or rank real Agent ID holders has to rebuild the same holder
checks and activity tracking from scratch.

Protocols need a neutral answer to a basic question: *"Is this Agent ID
genuinely active — and how consistently?"*

## 2. Solution

**AgentCheck** is a minimal, immutable on-chain registry where Agent ID
holders check in once per UTC day. Each check-in is recorded against the
holder's address, building a public, tamper-proof activity record:

- current consecutive-day **streak**,
- **lifetime check-ins**,
- **first-seen** and **last-active** days,
- global counters (unique agents, total check-ins).

Because the record lives in one small contract with public view functions,
**any other dApp can read it** — `isAgent`, `streakOf`, `checkInsOf`,
`lastCheckInDay`, `totalAgents`, `totalCheckIns` — and use it as a
composable **"proof of active agent"** primitive: gate a feature on a 7-day
streak, weight an airdrop by lifetime check-ins, rank a leaderboard by
consistency, all without re-implementing identity or activity logic.

AgentCheck itself is deliberately boring infrastructure: no owner, no admin,
no token, no fees, no approvals, nothing to rug and nothing to govern. Its
value is the dataset it accumulates and the standard it sets.

## 3. How Agent ID is integrated at the core

Agent ID is not a cosmetic login button in AgentCheck — it is the
**write permission for the entire system**:

- The contract is constructed with the official Agent ID registry address on
  BNB Chain: `0x60b9262456de011f7d15a54cdd8c48baaa8b022f`
  (SPACE ID Agent ID, ERC-721, non-transferable).
- The only state-changing function, `checkIn()`, begins with
  `balanceOf(msg.sender) > 0` against that registry and reverts for everyone
  else. No Agent ID → no record, no streak, no presence in the registry.
- Every stored record is therefore, by construction, a record of a verified
  Agent ID holder's activity. The reputation layer cannot be Sybil-filled by
  arbitrary fresh wallets: an address without an Agent ID simply cannot write.
- The frontend mirrors the same rule: it reads the visitor's holder status
  from the chain and enables the check-in button only for holders.

**Live verification (18 Nov 2026, read-only):** calling `balanceOf` on the
production Agent ID contract for the project wallet
`0xe1DB8E8aD894f9aE37194D8E70D1c375bD88D4f1` (holder of `nurbaya.ai`) returns
**1**, confirmed via two independent public BSC RPC endpoints — the gate
works against the real registry exactly as the tests assume.

## 4. Architecture

```
┌────────────────┐   checkIn()    ┌──────────────────────┐
│  Holder's own  │ ─────────────▶ │   AgentCheckIn.sol   │
│  EVM wallet    │  (user signs   │   BNB Chain, ~1.5 KB │
│  (EIP-1193)    │   & confirms)  │                      │
└────────────────┘                │  immutable, no owner │
                                  │  agentId = 0x60b9…2f │
┌────────────────┐   eth_call     │                      │
│  Any dApp /    │ ─────────────▶ │  streakOf / isAgent  │
│  frontend      │    (reads)     │  checkInsOf / totals │
└────────────────┘                └──────────────────────┘
```

- **`src/AgentCheckIn.sol`** — Solidity ^0.8.20, zero external dependencies
  (a 3-line `balanceOf` interface is declared inline). One immutable
  constructor argument (the Agent ID registry). Runtime size ≈ 1.5 KB.
- **Day model:** `day = block.timestamp / 86400` (UTC). A second check-in on
  the same day reverts; a check-in on the next day increments the streak; a
  gap of a day or more resets the streak to 1 while the lifetime count keeps
  growing. First-time check-ins emit `AgentRegistered`, every check-in emits
  `CheckedIn(agent, day, streak)` for easy off-chain indexing.
- **`frontend/index.html`** — a single self-contained page (vanilla JS, no
  build step, no external libraries). Standard EIP-1193 wallet connect,
  automatic switch to BSC, read-only stats via a public RPC with hand-rolled
  ABI calls, and a check-in button that sends the transaction through the
  user's own wallet for their own confirmation.
- **Tests** — Foundry suite with a mock Agent ID ERC-721 covering the gate,
  same-day double check-in, streak increment, streak reset, multi-agent
  counting and every view. **10/10 passing.**

## 5. How AgentCheck maps to the judging criteria

| Criterion (weight) | How AgentCheck answers it |
|---|---|
| **Agent ID application depth (30%)** | Agent ID is the sole write gate and the identity key of every record. Remove Agent ID and the product cannot function at all — the registry *is* Agent ID activity, productized. The composable views export that depth to the whole ecosystem: other dApps build on Agent ID through AgentCheck without touching the registry themselves. |
| **Practicality & feasibility (25%)** | The need is real and immediate: every campaign, airdrop and gated feature in the Agentic Wallet ecosystem needs to distinguish active Agent ID holders from dormant ones. The implementation is tiny, dependency-free, fully tested, and cheap to run forever (no servers, no keepers, no fees). |
| **Product completion (25%)** | Contract complete with a green test suite; frontend complete (connect, network switch, live stats, personal streak, check-in flow with receipt polling). Remaining launch steps are mechanical: deploy, verify on BscScan, paste the address into the frontend, host the page. |
| **Innovation (20%)** | Reframes Agent ID from a static name into a **living reputation primitive**: a shared, permissionless "proof of active agent" layer that other builders compose with. The daily-streak mechanic turns identity into an ongoing on-chain habit rather than a one-time claim — and produces exactly the recurring, unique-holder interaction data the ecosystem currently lacks. |

## 6. Growth plan — reaching (and passing) 30 unique Agent ID interactions

The Growth Award counts unique Agent ID addresses interacting with the
contract and transaction volume/count during the submission period. AgentCheck
is designed for precisely those metrics: **one transaction per holder per
day, every day** — recurring by construction.

1. **Seed network (days 1–3 after deployment).** The project is operated by an
   active Agent ID holder (`nurbaya.ai`) embedded in the Agent ID community
   (Boltbook Runes collab network, agent-card communities, X/CT circles
   around Agentic Wallet). Direct outreach to known holders with a simple
   ask: check in, start your streak. Target: first 30+ unique holders in the
   opening days — the Innovation Award eligibility threshold.
2. **Streak hook (ongoing).** A streak is a reason to return tomorrow.
   Daily reminder posts on X from the project account, a public streak
   leaderboard rendered from contract events, and "day N" milestones
   celebrated publicly turn one interaction into ~20 per holder across the
   submission window.
3. **Community promotion (parallel).** Original X content about the project
   and the Agent ID ecosystem under the campaign hashtags
   (#BinanceWalletHackathon, #AgenticWallet), submitted through the official
   campaign survey — this also enters the Community Promotion Campaign.
4. **Composability outreach.** Pitch 2–3 friendly ecosystem projects on
   reading `streakOf` for a perk (allowlist, badge, role). Each integration
   announcement drives its own holder base to check in.

Anti-gaming note: growth comes only from real holders transacting with their
own wallets. The contract cannot be interacted with by non-holders at all,
which keeps the interaction data clean by design.

## 7. Roadmap

| When | Step |
|---|---|
| Done | Concept, contract, 10/10 tests, frontend prototype |
| Launch day | Fund deployer with BNB gas → deploy to BSC mainnet with the production Agent ID address → verify source on BscScan |
| Launch day | Fill contract address into frontend, host page |
| Launch +1d | Submit project (name, website, contract address, Agent ID usage description) |
| Submission window | Daily community rhythm: reminders, leaderboard, milestone posts → ≥30 unique Agent ID holders, recurring daily transactions |
| By 9 Dec 2026 08:00 UTC | Submission-period data locked in for Growth Award ranking |
| Later (v2) | Off-chain indexer over `CheckedIn` events for a rich leaderboard site; SPACE ID name resolution display; streak-gated partner perks |

### v2 identity idea — and an honest constraint

A natural v2 would bind each record to the holder's Agent ID **token/name**
on-chain. A read-only probe of the production registry (18 Nov 2026) shows
this is **not currently possible via enumeration**: the contract does not
implement ERC721Enumerable (`supportsInterface(0x780e9d63)` returns false and
`tokenOfOwnerByIndex(address, 0)` reverts). v2 would therefore resolve names
through an off-chain indexer over the registry's Transfer events (plus SPACE
ID's resolution data) rather than on-chain calls — display-only, never part
of the trust path. The v1 design deliberately depends only on `balanceOf`,
the one registry function the hackathon documentation itself specifies.

## 8. Compliance checklist (against the hackathon safety red lines)

- [x] **No web QR-code / pairing-code login for Agentic Wallet.** The
      frontend uses only the standard EIP-1193 injected-wallet flow
      (`window.ethereum`). No pairing codes, no session storage of anyone's
      wallet session, no acting on a user's behalf.
- [x] **No bypassing user transaction confirmation.** The single transaction
      (check-in) is sent through the user's own wallet; the user reviews and
      confirms it themselves. There are no other transactions.
- [x] **No unauthorized or scheduled transfers.** The contract has no payable
      functions, moves no tokens or BNB, takes no approvals, and contains no
      transfer logic at all. Nothing is collected from anyone, ever.
- [x] **Open-source contracts with owner permissions disclosed.** The
      contract is MIT-licensed and will be verified on BscScan. Owner
      permissions: **none** — there is no owner, no admin, no pause, no
      upgrade path, and the Agent ID registry address is immutable.
- [x] **No Binance/BNB brand impersonation.** The project name is
      "AgentCheck" — it contains neither "Binance" nor "BNB", issues no
      token, and claims no official affiliation.
- [x] **No collection of sensitive credentials.** Nothing is collected: no
      seed phrases, private keys, API secrets or pairing codes are ever
      requested, transmitted or stored.
- [x] **No promised returns.** The product is a reputation record. The
      frontend states plainly that check-ins are free except network gas,
      that AgentCheck issues no token, and that it promises no returns or
      rewards.
- [x] **Not a trading product** — no prices, no swaps, no risk warnings
      required; the UI contains no financial claims of any kind.
- [x] **Not a wallet-lookup tool.** AgentCheck never resolves or exposes
      other people's wallets by name; a visitor sees global counters and
      *their own* record for *their own* connected address.
