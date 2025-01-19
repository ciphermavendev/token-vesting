// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenVesting is ReentrancyGuard, Ownable {
    struct VestingSchedule {
        bool initialized;
        address beneficiary;
        uint256 cliff;
        uint256 start;
        uint256 duration;
        uint256 totalAmount;
        uint256 releasedAmount;
        bool revocable;
        bool revoked;
    }

    // Token to be vested
    IERC20 public immutable token;

    // Vesting schedules for each beneficiary
    mapping(bytes32 => VestingSchedule) public vestingSchedules;
    
    // Total amount of tokens vested
    uint256 private totalVestedTokens;

    event VestingScheduleCreated(bytes32 indexed vestingScheduleId, address beneficiary);
    event TokensReleased(bytes32 indexed vestingScheduleId, uint256 amount);
    event VestingScheduleRevoked(bytes32 indexed vestingScheduleId);

    constructor(address tokenAddress) Ownable(msg.sender) {
        require(tokenAddress != address(0), "Token address cannot be zero");
        token = IERC20(tokenAddress);
    }

    function createVestingSchedule(
        address beneficiary,
        uint256 start,
        uint256 cliff,
        uint256 duration,
        uint256 amount,
        bool revocable
    ) external onlyOwner {
        require(beneficiary != address(0), "Beneficiary cannot be zero address");
        require(duration > 0, "Duration must be > 0");
        require(amount > 0, "Amount must be > 0");
        require(cliff <= duration, "Cliff must be <= duration");

        bytes32 vestingScheduleId = computeVestingScheduleId(beneficiary, start);
        require(!vestingSchedules[vestingScheduleId].initialized, "Vesting schedule already exists");

        uint256 currentBalance = token.balanceOf(address(this));
        require(currentBalance >= amount, "Not enough tokens");

        vestingSchedules[vestingScheduleId] = VestingSchedule({
            initialized: true,
            beneficiary: beneficiary,
            cliff: start + cliff,
            start: start,
            duration: duration,
            totalAmount: amount,
            releasedAmount: 0,
            revocable: revocable,
            revoked: false
        });

        totalVestedTokens += amount;
        emit VestingScheduleCreated(vestingScheduleId, beneficiary);
    }

    function release(bytes32 vestingScheduleId) external nonReentrant {
        VestingSchedule storage schedule = vestingSchedules[vestingScheduleId];
        require(schedule.initialized, "Vesting schedule does not exist");
        require(!schedule.revoked, "Vesting schedule revoked");
        require(block.timestamp >= schedule.cliff, "Cliff not reached");

        uint256 releasableAmount = computeReleasableAmount(schedule);
        require(releasableAmount > 0, "No tokens to release");

        schedule.releasedAmount += releasableAmount;
        totalVestedTokens -= releasableAmount;

        require(token.transfer(schedule.beneficiary, releasableAmount), "Token transfer failed");
        emit TokensReleased(vestingScheduleId, releasableAmount);
    }

    function revoke(bytes32 vestingScheduleId) external onlyOwner {
        VestingSchedule storage schedule = vestingSchedules[vestingScheduleId];
        require(schedule.initialized, "Vesting schedule does not exist");
        require(schedule.revocable, "Vesting schedule not revocable");
        require(!schedule.revoked, "Vesting schedule already revoked");

        uint256 releasableAmount = computeReleasableAmount(schedule);
        if (releasableAmount > 0) {
            schedule.releasedAmount += releasableAmount;
            totalVestedTokens -= releasableAmount;
            require(token.transfer(schedule.beneficiary, releasableAmount), "Token transfer failed");
            emit TokensReleased(vestingScheduleId, releasableAmount);
        }

        uint256 remainingAmount = schedule.totalAmount - schedule.releasedAmount;
        if (remainingAmount > 0) {
            totalVestedTokens -= remainingAmount;
            require(token.transfer(owner(), remainingAmount), "Token transfer failed");
        }

        schedule.revoked = true;
        emit VestingScheduleRevoked(vestingScheduleId);
    }

    function computeReleasableAmount(VestingSchedule memory schedule) 
        internal 
        view 
        returns (uint256) 
    {
        if (block.timestamp < schedule.cliff) {
            return 0;
        }

        if (block.timestamp >= schedule.start + schedule.duration) {
            return schedule.totalAmount - schedule.releasedAmount;
        }

        uint256 timeFromStart = block.timestamp - schedule.start;
        uint256 vestedAmount = (schedule.totalAmount * timeFromStart) / schedule.duration;
        return vestedAmount - schedule.releasedAmount;
    }

    function computeVestingScheduleId(address beneficiary, uint256 start) 
        internal 
        pure 
        returns (bytes32) 
    {
        return keccak256(abi.encodePacked(beneficiary, start));
    }

    function getVestingSchedule(bytes32 vestingScheduleId) 
        external 
        view 
        returns (VestingSchedule memory) 
    {
        return vestingSchedules[vestingScheduleId];
    }

    function getTotalVestedTokens() external view returns (uint256) {
        return totalVestedTokens;
    }
}