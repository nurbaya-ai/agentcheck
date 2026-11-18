// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Minimal mock Agent ID (ERC-721) for tests: just `mint` + `balanceOf`.
/// @dev Not part of the production deployment — test scaffolding only.
contract MockAgentID {
    mapping(address => uint256) private _balances;

    function mint(address to) external {
        _balances[to] += 1;
    }

    function balanceOf(address owner) external view returns (uint256) {
        return _balances[owner];
    }
}
