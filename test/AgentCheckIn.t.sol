// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AgentCheckIn} from "../src/AgentCheckIn.sol";
import {MockAgentID} from "./MockAgentID.sol";

contract AgentCheckInTest is Test {
    MockAgentID internal agentId;
    AgentCheckIn internal registry;

    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);
    address internal stranger = address(0x57A9);

    uint256 internal constant DAY0 = 20_000; // arbitrary UTC day number

    function setUp() public {
        agentId = new MockAgentID();
        registry = new AgentCheckIn(address(agentId));
        // Start one hour into DAY0 (safely inside the day).
        vm.warp(DAY0 * 1 days + 1 hours);
    }

    function _warpToDay(uint256 day) internal {
        vm.warp(day * 1 days + 1 hours);
    }

    // --- the gate -----------------------------------------------------------

    function test_NonHolderCannotCheckIn() public {
        assertFalse(registry.isAgent(stranger));
        vm.prank(stranger);
        vm.expectRevert(AgentCheckIn.NotAgentIdHolder.selector);
        registry.checkIn();
    }

    function test_IsAgentReflectsBalance() public {
        assertFalse(registry.isAgent(alice));
        agentId.mint(alice);
        assertTrue(registry.isAgent(alice));
    }

    // --- first check-in / registration --------------------------------------

    function test_HolderCheckInRegisters() public {
        agentId.mint(alice);

        vm.expectEmit(true, false, false, true, address(registry));
        emit AgentCheckIn.AgentRegistered(alice, DAY0);
        vm.expectEmit(true, false, false, true, address(registry));
        emit AgentCheckIn.CheckedIn(alice, DAY0, 1);
        vm.prank(alice);
        registry.checkIn();

        assertEq(registry.totalAgents(), 1);
        assertEq(registry.totalCheckIns(), 1);
        assertEq(registry.streakOf(alice), 1);
        assertEq(registry.checkInsOf(alice), 1);
        assertEq(registry.lastCheckInDay(alice), DAY0);
        assertEq(registry.firstCheckInDay(alice), DAY0);
        assertTrue(registry.hasCheckedInToday(alice));
    }

    function test_SecondCheckInSameDayReverts() public {
        agentId.mint(alice);
        vm.prank(alice);
        registry.checkIn();

        // Later the same UTC day still counts as the same day.
        vm.warp(DAY0 * 1 days + 23 hours);
        vm.prank(alice);
        vm.expectRevert(AgentCheckIn.AlreadyCheckedInToday.selector);
        registry.checkIn();
    }

    // --- streaks --------------------------------------------------------------

    function test_NextDayCheckInIncrementsStreak() public {
        agentId.mint(alice);
        vm.prank(alice);
        registry.checkIn();

        _warpToDay(DAY0 + 1);
        assertFalse(registry.hasCheckedInToday(alice));
        vm.prank(alice);
        registry.checkIn();

        assertEq(registry.streakOf(alice), 2);
        assertEq(registry.checkInsOf(alice), 2);
        assertEq(registry.lastCheckInDay(alice), DAY0 + 1);
        assertEq(registry.firstCheckInDay(alice), DAY0);
        assertTrue(registry.hasCheckedInToday(alice));
    }

    function test_ThreeConsecutiveDaysStreakThree() public {
        agentId.mint(alice);
        for (uint256 i = 0; i < 3; i++) {
            _warpToDay(DAY0 + i);
            vm.prank(alice);
            registry.checkIn();
        }
        assertEq(registry.streakOf(alice), 3);
        assertEq(registry.checkInsOf(alice), 3);
        assertEq(registry.totalCheckIns(), 3);
        assertEq(registry.totalAgents(), 1);
    }

    function test_SkippedDayResetsStreak() public {
        agentId.mint(alice);
        vm.prank(alice);
        registry.checkIn(); // DAY0, streak 1

        _warpToDay(DAY0 + 1);
        vm.prank(alice);
        registry.checkIn(); // streak 2
        assertEq(registry.streakOf(alice), 2);

        // Skip DAY0+2 entirely; check in again on DAY0+3.
        _warpToDay(DAY0 + 3);
        vm.prank(alice);
        registry.checkIn();

        assertEq(registry.streakOf(alice), 1); // reset
        assertEq(registry.checkInsOf(alice), 3); // lifetime count keeps growing
        assertEq(registry.lastCheckInDay(alice), DAY0 + 3);
        assertEq(registry.firstCheckInDay(alice), DAY0);
    }

    // --- multiple agents / global stats ---------------------------------------

    function test_TwoHoldersCountAsTwoUniqueAgents() public {
        agentId.mint(alice);
        agentId.mint(bob);

        vm.prank(alice);
        registry.checkIn();
        vm.prank(bob);
        registry.checkIn();

        assertEq(registry.totalAgents(), 2);
        assertEq(registry.totalCheckIns(), 2);

        _warpToDay(DAY0 + 1);
        vm.prank(alice);
        registry.checkIn();

        // Returning agents do not inflate the unique count.
        assertEq(registry.totalAgents(), 2);
        assertEq(registry.totalCheckIns(), 3);
        assertEq(registry.streakOf(alice), 2);
        assertEq(registry.streakOf(bob), 1);
    }

    // --- views for unknown addresses ------------------------------------------

    function test_ViewsForNeverCheckedInAreZero() public {
        agentId.mint(alice); // holds an Agent ID but never checked in
        assertEq(registry.streakOf(alice), 0);
        assertEq(registry.checkInsOf(alice), 0);
        assertEq(registry.lastCheckInDay(alice), 0);
        assertEq(registry.firstCheckInDay(alice), 0);
        assertFalse(registry.hasCheckedInToday(alice));
        assertEq(registry.totalAgents(), 0);
        assertEq(registry.totalCheckIns(), 0);
    }

    function test_CurrentDayMatchesWarp() public {
        assertEq(registry.currentDay(), DAY0);
        _warpToDay(DAY0 + 7);
        assertEq(registry.currentDay(), DAY0 + 7);
    }
}
