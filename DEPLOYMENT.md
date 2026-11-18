# AgentCheck — Deployment Record

- **Contract:** AgentCheckIn
- **Address:** 0x19c8fc3d4bf54139d5c6afb0d744fe614059ae84
- **Network:** BNB Smart Chain (chainId 56)
- **Deploy tx:** 0x0ae16a63546bcfa0fd34cd380b68c114f20fb61daf172592e8bcbb52314c1f35
- **Block:** 134283769
- **Deployer:** 0xB4e8d9d11dC4872Eb9Be2D8404F149Deb323C8C7 (work EOA)
- **Constructor arg:** Agent ID registry 0x60b9262456de011f7d15a54cdd8c48baaa8b022f
- **Gas used:** 379700 @ 0.05 gwei = 0.0000189850 BNB
- **Runtime size:** 1496 bytes (matches local build)
- **Verified on-chain:** agentId() returns the official registry; totalAgents/totalCheckIns = 0 at deploy; isAgent(agentic wallet) = true; checkIn() from a non-holder reverts NotAgentIdHolder.
- **Source verification:** Sourcify exact_match (job dccb31f8-07f7-430b-8f89-952928ab606c). BscScan verification still to do (needs BscScan account/API key).
- **Frontend:** index.html AGENTCHECK_ADDRESS set to the deployed address.
- **Deployed:** 18 Nov 2026 ~22:2x WITA.
