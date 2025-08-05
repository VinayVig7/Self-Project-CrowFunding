// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {DeployCrowFunding} from "script/DeployCrowFunding.s.sol";
import {CrowFunding} from "src/CrowFunding.sol";

contract DeployCrowFundingTest is Test {
    DeployCrowFunding public deployScript;

    function setUp() public {
        deployScript = new DeployCrowFunding();
    }

    function testDeployCrowFundingContract() public {
        CrowFunding deployed = deployScript.run();

        assertEq(deployed.i_goal(), 0.1 ether);
        assertEq(deployed.i_minimumContribution(), 0.001 ether);
        assertEq(deployed.getBalance(), 0);
    }
}
