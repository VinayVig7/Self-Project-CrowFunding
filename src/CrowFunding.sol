// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract CrowFunding {
    ////////////
    // Errors //
    ///////////
    error CrowFunding__CrowFundingIsNotOpen();
    error CrowFunding__LessThanMinimumContribution();
    error CrowFunding__ClaimFundingFailed();
    error CrowFunding__ClaimFundingThroughCallFailed();
    error CrowFunding__NotOwnerOfTheContract();
    error CrowFunding__WithdrawFundFailed();
    error CrowFunding__WithdrawFundingThroughCallFailed();
    error CrowFunding__NothingToWithdraw();
    error CrowFunding__FallbackFunctionCalled();

    //////////
    // Enum //
    /////////
    enum crowFundingStatus {
        FUNDING,
        SUCCESSFUL,
        FAILED
    }

    /////////////////////
    // State Variables //
    ////////////////////
    uint256 public constant fundingTime = 30 days;
    uint256 public immutable i_deadline;
    uint256 public immutable i_goal;
    uint256 public immutable i_minimumContribution;
    uint256 public immutable i_deployTimeStamp;
    address private immutable i_owner;
    crowFundingStatus public s_status;
    mapping(address user => uint256 amount) s_contributors;

    ////////////
    // Events //
    ///////////
    event ContributionMade(address indexed contributor, uint256 amount);
    event FundsClaimed(address indexed owner, uint256 amount);
    event WithdrawClaimed(address indexed user, uint256 amount);

    ///////////////
    // Modifiers //
    //////////////
    /**
     * @notice Updates the status of the crowdfunding campaign based on deadline and funds raised
     */
    modifier crowFundingStatusCheck() {
        if (block.timestamp <= i_deadline) {
            s_status = crowFundingStatus.FUNDING;
        } else if (
            block.timestamp > i_deadline && address(this).balance >= i_goal
        ) {
            s_status = crowFundingStatus.SUCCESSFUL;
        } else {
            s_status = crowFundingStatus.FAILED;
        }
        _;
    }

    /**
     * @notice Restricts function access to only the contract owner
     */
    modifier ownerOnly() {
        if (msg.sender != i_owner) {
            revert CrowFunding__NotOwnerOfTheContract();
        }
        _;
    }

    ///////////////
    // Functions //
    //////////////
    /**
     * @notice Initializes the crowdfunding contract with goal and minimum contribution
     * @param goal The funding goal in wei
     * @param minimumContribution The minimum ETH a contributor must send
     */
    constructor(uint256 goal, uint256 minimumContribution) {
        i_goal = goal;
        i_minimumContribution = minimumContribution;
        i_deployTimeStamp = block.timestamp;
        i_deadline = i_deployTimeStamp + fundingTime;
        i_owner = msg.sender;
        s_status = crowFundingStatus.FUNDING;
    }

    /**
     * @notice Allows users to contribute ETH to the crowdfunding campaign
     * @dev Reverts if funding is closed or contribution is below minimum
     */
    function contribute() public payable crowFundingStatusCheck {
        if (s_status != crowFundingStatus.FUNDING) {
            revert CrowFunding__CrowFundingIsNotOpen();
        }
        if (msg.value < i_minimumContribution) {
            revert CrowFunding__LessThanMinimumContribution();
        }
        s_contributors[msg.sender] += msg.value;
        emit ContributionMade(msg.sender, msg.value);
    }

    /**
     * @notice Allows the contract owner to claim the funds if the goal is met before the deadline
     * @dev Only callable by the owner when the campaign is marked successful
     */
    function claimFunds() public crowFundingStatusCheck ownerOnly {
        if (s_status != crowFundingStatus.SUCCESSFUL) {
            revert CrowFunding__ClaimFundingFailed();
        }
        (bool success, ) = payable(i_owner).call{value: address(this).balance}(
            ""
        );
        if (!success) {
            revert CrowFunding__ClaimFundingThroughCallFailed();
        }
        emit FundsClaimed(i_owner, address(this).balance);
    }

    /**
     * @notice Allows contributors to withdraw their funds if the campaign fails
     * @dev Reverts if campaign succeeded or if the user has no funds to withdraw
     */
    function withdraw() public crowFundingStatusCheck {
        if (s_status == crowFundingStatus.SUCCESSFUL) {
            revert CrowFunding__WithdrawFundFailed();
        }

        uint256 contributedAmount = s_contributors[msg.sender];
        if (contributedAmount == 0) {
            revert CrowFunding__NothingToWithdraw();
        }

        s_contributors[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: contributedAmount}(
            ""
        );
        if (!success) {
            revert CrowFunding__WithdrawFundingThroughCallFailed();
        }

        emit WithdrawClaimed(msg.sender, contributedAmount);
    }

    //////////////////////
    // Getters Function //
    /////////////////////
    /**
     * @notice Returns the current ETH balance of the crowdfunding contract
     * @return The contract balance in wei
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Returns the total amount contributed by a specific address
     * @param contributor The address of the contributor
     * @return The total contribution amount in wei
     */
    function getContribution(
        address contributor
    ) public view returns (uint256) {
        return s_contributors[contributor];
    }

    /**
     * @notice Returns the current status of the crowdfunding campaign
     * @return The campaign status as enum value
     */
    function getStatus() public crowFundingStatusCheck returns (crowFundingStatus) {
        return s_status;
    }

    /**
     * @notice Accept ETH sent directly by redirecting to contribute()
     */
    receive() external payable {
        contribute(); // redirect to your main logic
    }

    /**
     * @notice Fallback function in case of incorrect call
     */
    fallback() external payable {
        revert CrowFunding__FallbackFunctionCalled();
    }
}
