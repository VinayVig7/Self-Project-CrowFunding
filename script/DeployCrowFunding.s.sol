// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {CrowFunding} from "src/CrowFunding.sol";

contract DeployCrowFunding is Script {
    CrowFunding deployer;
    uint256 goalAmount = 0.1 ether;
    uint256 minimumContribution = 0.001 ether;

    function run() public returns (CrowFunding){
        vm.startBroadcast();
        deployer = new CrowFunding(goalAmount, minimumContribution);
        vm.stopBroadcast();
        return deployer;
    }
}