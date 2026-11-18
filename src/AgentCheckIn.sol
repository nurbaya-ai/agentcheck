// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Minimal read-only interface for an ERC-721 contract.
/// @dev AgentCheck only ever needs `balanceOf` — the Agent ID holder check.
interface IERC721Balance {
    function balanceOf(address owner) external view returns (uint256);
}

/// @title AgentCheckIn
/// @notice Agent ID-gated daily check-in and reputation registry for the
///         Agent ID ecosystem on BNB Chain.
///
///         Only holders of an Agent ID (an ERC-721 "name.ai" identity issued
///         to Agentic Wallet users) can check in, once per UTC day. The
///         contract tracks per-agent streaks, lifetime check-ins and global
///         participation, and exposes them through public view functions so
///         ANY other dApp can read them — a composable "proof of active
///         agent" primitive keyed on Agent ID.
///
/// @dev Deliberately minimal and immutable:
///      - no owner, no admin, no upgrade path;
///      - no payable functions, no token handling, no approvals;
///      - the Agent ID contract address is fixed at deployment (immutable).
///      The only state-changing function is `checkIn()`, and the only thing
///      it can ever write is the caller's own check-in record.
contract AgentCheckIn {
    /// @notice The Agent ID contract (SPACE ID Agent ID, BNB Chain mainnet:
    ///         0x60b9262456de011f7d15a54cdd8c48baaa8b022f in production).
    IERC721Balance public immutable agentId;

    struct AgentStats {
        uint256 streak; // consecutive-day streak as of `lastDay`
        uint256 totalCheckIns; // lifetime check-ins
        uint256 firstDay; // UTC day of first check-in (0 = never)
        uint256 lastDay; // UTC day of most recent check-in
        bool registered; // true after the first check-in
    }

    mapping(address => AgentStats) private _agents;

    /// @notice Number of unique Agent ID addresses that have ever checked in.
    uint256 public totalAgents;

    /// @notice Total check-ins recorded across all agents.
    uint256 public totalCheckIns;

    event CheckedIn(address indexed agent, uint256 day, uint256 streak);
    event AgentRegistered(address indexed agent, uint256 day);

    error NotAgentIdHolder();
    error AlreadyCheckedInToday();

    constructor(address agentId_) {
        require(agentId_ != address(0), "AgentCheckIn: zero address");
        agentId = IERC721Balance(agentId_);
    }

    /// @notice Current UTC day number (days since the Unix epoch).
    function currentDay() public view returns (uint256) {
        return block.timestamp / 1 days;
    }

    /// @notice True if `account` currently holds at least one Agent ID.
    function isAgent(address account) public view returns (bool) {
        return agentId.balanceOf(account) > 0;
    }

    /// @notice Check in for today. Caller must hold an Agent ID and must not
    ///         have checked in already today (UTC).
    function checkIn() external {
        if (agentId.balanceOf(msg.sender) == 0) revert NotAgentIdHolder();

        uint256 today = currentDay();
        AgentStats storage stats = _agents[msg.sender];

        if (stats.registered && stats.lastDay == today) {
            revert AlreadyCheckedInToday();
        }

        if (!stats.registered) {
            stats.registered = true;
            stats.firstDay = today;
            stats.streak = 1;
            totalAgents += 1;
            emit AgentRegistered(msg.sender, today);
        } else if (stats.lastDay == today - 1) {
            // Yesterday was the last check-in day: the streak continues.
            stats.streak += 1;
        } else {
            // At least one day was skipped: the streak restarts.
            stats.streak = 1;
        }

        stats.lastDay = today;
        stats.totalCheckIns += 1;
        totalCheckIns += 1;

        emit CheckedIn(msg.sender, today, stats.streak);
    }

    /// @notice True if `account` has already checked in today (UTC).
    function hasCheckedInToday(address account) public view returns (bool) {
        AgentStats storage stats = _agents[account];
        return stats.registered && stats.lastDay == currentDay();
    }

    /// @notice Current consecutive-day streak of `account` (0 if never).
    /// @dev The streak is stored as of the last check-in day; a streak whose
    ///      last check-in is older than yesterday has lapsed — readers that
    ///      need a "live" streak should also check `lastCheckInDay`.
    function streakOf(address account) public view returns (uint256) {
        return _agents[account].streak;
    }

    /// @notice Lifetime check-ins of `account`.
    function checkInsOf(address account) public view returns (uint256) {
        return _agents[account].totalCheckIns;
    }

    /// @notice UTC day of `account`'s most recent check-in (0 if never).
    function lastCheckInDay(address account) public view returns (uint256) {
        return _agents[account].lastDay;
    }

    /// @notice UTC day of `account`'s first check-in (0 if never).
    function firstCheckInDay(address account) public view returns (uint256) {
        return _agents[account].firstDay;
    }
}
