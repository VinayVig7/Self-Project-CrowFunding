// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {CrowFunding} from "src/CrowFunding.sol";

contract CrowFundingTest is Test {
    /////////////////////
    // State Variables //
    ////////////////////
    CrowFunding crowFunding;
    uint256 goalAmount = 10 ether;
    uint256 minimumContribution = 1e16;
    address OWNER = makeAddr("owner");
    address USER = makeAddr("user");

    ///////////////
    // Functions //
    //////////////
    function setUp() public {
        vm.prank(OWNER);
        crowFunding = new CrowFunding(goalAmount, minimumContribution);
    }

    function testConstructor() public view {
        // Assert
        assertEq(crowFunding.i_goal(), goalAmount);
        assertEq(crowFunding.i_minimumContribution(), minimumContribution);
        assertEq(crowFunding.i_minimumContribution(), minimumContribution);
        assertEq(crowFunding.i_deployTimeStamp(), block.timestamp);
        assertEq(
            crowFunding.i_deadline(),
            crowFunding.i_deployTimeStamp() + crowFunding.fundingTime()
        );
    }

    function testContribute() public {
        // Arrange
        uint256 contributionValue = 1e17;

        // Act
        vm.deal(USER, 1 ether);
        vm.prank(USER);
        crowFunding.contribute{value: contributionValue}();

        // Assert
        assertEq(crowFunding.getContribution(USER), contributionValue);
    }

    function testContributeNotWorkingAfterTimeEnds() public {
        // Arrange
        uint256 contributionValue = 1e17;
        uint256 increasingTimeToEndFundPeriod = crowFunding
            .i_deployTimeStamp() +
            crowFunding.fundingTime() +
            1 seconds;

        // Act
        vm.deal(USER, 1 ether);
        vm.warp(increasingTimeToEndFundPeriod);

        // Assert
        vm.prank(USER);
        vm.expectRevert(CrowFunding.CrowFunding__CrowFundingIsNotOpen.selector);
        crowFunding.contribute{value: contributionValue}();
    }

    function testContributeNotWorkingIfAmountIsLessThanMinimumContribution()
        public
    {
        // Arrange
        uint256 contributionValue = 1e15;

        // Act
        vm.deal(USER, 1 ether);

        // Assert
        vm.prank(USER);
        vm.expectRevert(
            CrowFunding.CrowFunding__LessThanMinimumContribution.selector
        );
        crowFunding.contribute{value: contributionValue}();
    }

    function testClaimFundsWorking() public {
        // Arrange
        uint256 contributionValueExceedToMeetGoal = 10 ether + 1;
        uint256 increasingTimeToEndFundPeriod = crowFunding
            .i_deployTimeStamp() +
            crowFunding.fundingTime() +
            1 seconds;

        // Act
        vm.deal(USER, 11 ether);
        vm.startPrank(USER);
        crowFunding.contribute{value: contributionValueExceedToMeetGoal}();
        vm.stopPrank();
        vm.warp(increasingTimeToEndFundPeriod);

        // Assert
        uint256 balanceBeforeClaimingFunds = crowFunding.getBalance();
        uint256 balanceOwnerBefore = address(OWNER).balance;
        vm.prank(OWNER);
        crowFunding.claimFunds();
        uint256 balanceAfterClaimingFunds = crowFunding.getBalance();
        uint256 balanceOwnerAfter = address(OWNER).balance;

        assertEq(
            balanceBeforeClaimingFunds,
            balanceAfterClaimingFunds + contributionValueExceedToMeetGoal
        );
        assertEq(
            balanceOwnerBefore,
            balanceOwnerAfter - contributionValueExceedToMeetGoal
        );
    }

    function testClaimFundsCantBeClaimedOtherThenOwner() public {
        // Arrange
        uint256 contributionValueExceedToMeetGoal = 10 ether + 1;
        uint256 increasingTimeToEndFundPeriod = crowFunding
            .i_deployTimeStamp() +
            crowFunding.fundingTime() +
            1 seconds;

        // Act
        vm.deal(USER, 11 ether);
        vm.startPrank(USER);
        crowFunding.contribute{value: contributionValueExceedToMeetGoal}();
        vm.stopPrank();
        vm.warp(increasingTimeToEndFundPeriod);

        // Assert
        vm.prank(USER);
        vm.expectRevert(
            CrowFunding.CrowFunding__NotOwnerOfTheContract.selector
        );
        crowFunding.claimFunds();
    }

    function testClaimFundsNotPossibleWithoutGoalMet() public {
        // Arrange
        uint256 contribution = 9 ether;
        uint256 increasingTimeToEndFundPeriod = crowFunding
            .i_deployTimeStamp() +
            crowFunding.fundingTime() +
            1 seconds;

        // Act
        vm.deal(USER, 11 ether);
        vm.startPrank(USER);
        crowFunding.contribute{value: contribution}();
        vm.stopPrank();
        vm.warp(increasingTimeToEndFundPeriod);

        // Assert
        vm.prank(OWNER);
        vm.expectRevert(CrowFunding.CrowFunding__ClaimFundingFailed.selector);
        crowFunding.claimFunds();
    }

    function testClaimFundsNotPossibleWithoutFundingTimeReached() public {
        // Arrange
        uint256 contribution = 10 ether + 1;

        // Act
        vm.deal(USER, 11 ether);
        vm.startPrank(USER);
        crowFunding.contribute{value: contribution}();
        vm.stopPrank();

        // Assert
        vm.prank(OWNER);
        vm.expectRevert(CrowFunding.CrowFunding__ClaimFundingFailed.selector);
        crowFunding.claimFunds();
    }

    function testWithdrawWorking() public {
        // Arrange
        uint256 contribution = 1 ether;

        // Act
        vm.deal(USER, 11 ether);
        vm.startPrank(USER);
        crowFunding.contribute{value: contribution}();
        uint256 contributionAmountBeforeWithdraw = crowFunding.getContribution(
            USER
        );
        crowFunding.withdraw();
        uint256 contributionAmountAfterWithdraw = crowFunding.getContribution(
            USER
        );
        vm.stopPrank();

        // Assert
        assertEq(
            contributionAmountBeforeWithdraw,
            contributionAmountAfterWithdraw + contribution
        );
    }

    function testWithdrawNotPossibleAfterSuccessfulFundingAndGoal() public {
        // Arrange
        uint256 contribution = 11 ether;
        uint256 increasingTimeToEndFundPeriod = crowFunding
            .i_deployTimeStamp() +
            crowFunding.fundingTime() +
            1 seconds;

        // Act
        vm.deal(USER, 11 ether);
        vm.startPrank(USER);
        crowFunding.contribute{value: contribution}();
        vm.stopPrank();
        vm.warp(increasingTimeToEndFundPeriod);

        // Assert
        vm.prank(USER);
        vm.expectRevert(CrowFunding.CrowFunding__WithdrawFundFailed.selector);
        crowFunding.withdraw();
    }

    function testWithdrawNotPossibleWithZeroContribution() public {
        // Arrange
        uint256 contribution = 11 ether;
        address claimerWithoutContribution = makeAddr("claimer");

        // Act
        vm.deal(USER, 11 ether);
        vm.prank(USER);
        crowFunding.contribute{value: contribution}();

        // Assert
        vm.prank(claimerWithoutContribution);
        vm.expectRevert(CrowFunding.CrowFunding__NothingToWithdraw.selector);
        crowFunding.withdraw();
    }

    function testGetStatus() public {
        // Arrange
        assertEq(uint(crowFunding.getStatus()), 0); // 0 means in FUNDING state
        uint256 contribution = 11 ether;
        uint256 increasingTimeToEndFundPeriod = crowFunding
            .i_deployTimeStamp() +
            crowFunding.fundingTime() +
            1 seconds;

        // Act
        vm.deal(USER, 11 ether);
        vm.prank(USER);
        crowFunding.contribute{value: contribution}();
        vm.warp(increasingTimeToEndFundPeriod);

        // Assert
        assertEq(uint(crowFunding.getStatus()), 1); // 1 means SUCCESS
    }

    function testReceiveFunctionTriggersContribute() public {
        // Arrange
        vm.deal(USER, 1 ether);
        vm.prank(USER);

        // Act
        (bool success, ) = address(crowFunding).call{value: 1 ether}("");
        assertTrue(success);

        // Assert
        uint256 contribution = crowFunding.getContribution(USER);
        assertEq(contribution, 1 ether);
    }

    function testFallbackFunctionReverts() public {
        // Arrange, Act
        (bool success, bytes memory data) = address(crowFunding).call{
            value: 0.1 ether
        }(abi.encodeWithSignature("nonExistentFunction()"));

        // Assert
        assertFalse(success);
        assertEq(
            bytes4(data),
            CrowFunding.CrowFunding__FallbackFunctionCalled.selector
        );
    }
}
