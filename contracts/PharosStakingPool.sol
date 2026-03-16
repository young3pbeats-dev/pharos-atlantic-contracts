// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PharosStakingPool
 * @author young3pbeats-dev
 * @notice Epoch-based ETH staking pool with on-chain reward calculation,
 *         tiered multipliers, and full event logging.
 *         Deployed on Pharos Atlantic Testnet.
 *
 * Architecture:
 *  - Users stake ETH directly (no ERC20 required)
 *  - Rewards accrue per-block, scaled by a tiered multiplier based on stake size
 *  - Owner can fund the reward pool and manage epochs
 *  - Emergency withdraw available with penalty (sent to reward pool)
 */
contract PharosStakingPool {

    // ─────────────────────────────────────────────
    //  CONSTANTS
    // ─────────────────────────────────────────────

    uint256 public constant BASE_REWARD_RATE   = 1e12;  // wei per block per wei staked (base)
    uint256 public constant EPOCH_DURATION     = 200;   // blocks per epoch
    uint256 public constant EMERGENCY_PENALTY  = 10;    // 10% penalty on emergency withdraw

    // Tier thresholds (in wei)
    uint256 public constant TIER1_THRESHOLD = 0.01 ether;  // Bronze
    uint256 public constant TIER2_THRESHOLD = 0.05 ether;  // Silver
    uint256 public constant TIER3_THRESHOLD = 0.1 ether;   // Gold

    // Tier multipliers (basis points, 10000 = 1x)
    uint256 public constant TIER1_MULTIPLIER = 10000; // 1.0x
    uint256 public constant TIER2_MULTIPLIER = 12500; // 1.25x
    uint256 public constant TIER3_MULTIPLIER = 15000; // 1.50x
    uint256 public constant TIER4_MULTIPLIER = 20000; // 2.00x (Gold+)

    // ─────────────────────────────────────────────
    //  STATE
    // ─────────────────────────────────────────────

    address public owner;
    uint256 public currentEpoch;
    uint256 public epochStartBlock;
    uint256 public totalStaked;
    uint256 public rewardPool;

    struct StakeInfo {
        uint256 amount;
        uint256 stakedAtBlock;
        uint256 lastClaimBlock;
        uint256 totalClaimed;
        uint256 epochEnteredAt;
    }

    mapping(address => StakeInfo) public stakes;
    mapping(uint256 => uint256) public epochTotalStaked; // epoch => totalStaked snapshot

    // ─────────────────────────────────────────────
    //  EVENTS
    // ─────────────────────────────────────────────

    event Staked(address indexed user, uint256 amount, uint256 tier, uint256 epoch, uint256 blockNumber);
    event Unstaked(address indexed user, uint256 amount, uint256 rewardClaimed, uint256 epoch);
    event RewardClaimed(address indexed user, uint256 reward, uint256 epoch, uint256 blockNumber);
    event EmergencyWithdraw(address indexed user, uint256 amount, uint256 penalty);
    event EpochAdvanced(uint256 newEpoch, uint256 blockNumber, uint256 totalStakedSnapshot);
    event RewardPoolFunded(address indexed funder, uint256 amount, uint256 newTotal);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ─────────────────────────────────────────────
    //  MODIFIERS
    // ─────────────────────────────────────────────

    modifier onlyOwner() {
        require(msg.sender == owner, "PharosStaking: not owner");
        _;
    }

    modifier hasStake() {
        require(stakes[msg.sender].amount > 0, "PharosStaking: no active stake");
        _;
    }

    // ─────────────────────────────────────────────
    //  CONSTRUCTOR
    // ─────────────────────────────────────────────

    constructor() {
        owner = msg.sender;
        currentEpoch = 1;
        epochStartBlock = block.number;
        emit EpochAdvanced(1, block.number, 0);
    }

    // ─────────────────────────────────────────────
    //  CORE: STAKE
    // ─────────────────────────────────────────────

    /**
     * @notice Stake ETH into the pool.
     *         Existing stake is topped up; pending rewards are auto-claimed.
     */
    function stake() external payable {
        require(msg.value > 0, "PharosStaking: zero value");

        _tryAdvanceEpoch();

        StakeInfo storage s = stakes[msg.sender];

        // If re-staking, claim pending rewards first
        if (s.amount > 0) {
            uint256 pending = _calculateReward(msg.sender);
            if (pending > 0) {
                _distributReward(msg.sender, pending);
            }
        }

        s.amount          += msg.value;
        s.stakedAtBlock    = block.number;
        s.lastClaimBlock   = block.number;
        s.epochEnteredAt   = currentEpoch;
        totalStaked        += msg.value;

        uint256 tier = _getTier(s.amount);
        emit Staked(msg.sender, msg.value, tier, currentEpoch, block.number);
    }

    // ─────────────────────────────────────────────
    //  CORE: UNSTAKE
    // ─────────────────────────────────────────────

    /**
     * @notice Unstake all ETH and claim pending rewards.
     */
    function unstake() external hasStake {
        _tryAdvanceEpoch();

        StakeInfo storage s = stakes[msg.sender];
        uint256 amount  = s.amount;
        uint256 pending = _calculateReward(msg.sender);

        totalStaked -= amount;
        delete stakes[msg.sender];

        // Send staked amount
        (bool sentStake,) = payable(msg.sender).call{value: amount}("");
        require(sentStake, "PharosStaking: ETH transfer failed");

        // Send reward if available
        if (pending > 0) {
            _distributReward(msg.sender, pending);
        }

        emit Unstaked(msg.sender, amount, pending, currentEpoch);
    }

    // ─────────────────────────────────────────────
    //  CORE: CLAIM REWARDS
    // ─────────────────────────────────────────────

    /**
     * @notice Claim accrued rewards without unstaking.
     */
    function claimRewards() external hasStake {
        _tryAdvanceEpoch();

        uint256 pending = _calculateReward(msg.sender);
        require(pending > 0, "PharosStaking: nothing to claim");

        stakes[msg.sender].lastClaimBlock = block.number;
        _distributReward(msg.sender, pending);

        emit RewardClaimed(msg.sender, pending, currentEpoch, block.number);
    }

    // ─────────────────────────────────────────────
    //  EMERGENCY WITHDRAW (with penalty)
    // ─────────────────────────────────────────────

    /**
     * @notice Emergency exit: withdraw stake with a 10% penalty.
     *         Penalty is sent to the reward pool.
     */
    function emergencyWithdraw() external hasStake {
        StakeInfo storage s = stakes[msg.sender];
        uint256 amount  = s.amount;
        uint256 penalty = (amount * EMERGENCY_PENALTY) / 100;
        uint256 payout  = amount - penalty;

        totalStaked -= amount;
        rewardPool  += penalty;
        delete stakes[msg.sender];

        (bool sent,) = payable(msg.sender).call{value: payout}("");
        require(sent, "PharosStaking: transfer failed");

        emit EmergencyWithdraw(msg.sender, payout, penalty);
    }

    // ─────────────────────────────────────────────
    //  OWNER FUNCTIONS
    // ─────────────────────────────────────────────

    /**
     * @notice Fund the reward pool with ETH.
     */
    function fundRewardPool() external payable onlyOwner {
        require(msg.value > 0, "PharosStaking: zero value");
        rewardPool += msg.value;
        emit RewardPoolFunded(msg.sender, msg.value, rewardPool);
    }

    /**
     * @notice Manually advance epoch (owner only, as safety valve).
     */
    function forceAdvanceEpoch() external onlyOwner {
        _advanceEpoch();
    }

    /**
     * @notice Transfer ownership.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "PharosStaking: zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    // ─────────────────────────────────────────────
    //  VIEW FUNCTIONS
    // ─────────────────────────────────────────────

    /**
     * @notice Returns pending reward for a user (not yet claimed).
     */
    function pendingReward(address user) external view returns (uint256) {
        return _calculateReward(user);
    }

    /**
     * @notice Returns the tier (1–4) for a given stake amount.
     */
    function getTier(address user) external view returns (uint256) {
        return _getTier(stakes[user].amount);
    }

    /**
     * @notice Full stake info for a user.
     */
    function getStakeInfo(address user) external view returns (
        uint256 amount,
        uint256 stakedAtBlock,
        uint256 lastClaimBlock,
        uint256 totalClaimed,
        uint256 epochEnteredAt,
        uint256 tier,
        uint256 pending
    ) {
        StakeInfo memory s = stakes[user];
        return (
            s.amount,
            s.stakedAtBlock,
            s.lastClaimBlock,
            s.totalClaimed,
            s.epochEnteredAt,
            _getTier(s.amount),
            _calculateReward(user)
        );
    }

    /**
     * @notice Pool-level stats.
     */
    function getPoolStats() external view returns (
        uint256 epoch,
        uint256 epochStart,
        uint256 blocksUntilNextEpoch,
        uint256 staked,
        uint256 rewards
    ) {
        uint256 elapsed = block.number - epochStartBlock;
        uint256 remaining = elapsed >= EPOCH_DURATION ? 0 : EPOCH_DURATION - elapsed;
        return (currentEpoch, epochStartBlock, remaining, totalStaked, rewardPool);
    }

    // ─────────────────────────────────────────────
    //  INTERNAL LOGIC
    // ─────────────────────────────────────────────

    function _calculateReward(address user) internal view returns (uint256) {
        StakeInfo memory s = stakes[user];
        if (s.amount == 0) return 0;

        uint256 blocks     = block.number - s.lastClaimBlock;
        uint256 multiplier = _getTierMultiplier(s.amount);
        uint256 reward     = (s.amount * BASE_REWARD_RATE * blocks * multiplier) / 10000;

        // Cap reward to available pool
        return reward > rewardPool ? rewardPool : reward;
    }

    function _distributReward(address user, uint256 amount) internal {
        if (amount == 0 || rewardPool < amount) return;
        rewardPool -= amount;
        stakes[user].totalClaimed += amount;
        stakes[user].lastClaimBlock = block.number;

        (bool sent,) = payable(user).call{value: amount}("");
        require(sent, "PharosStaking: reward transfer failed");
    }

    function _getTier(uint256 amount) internal pure returns (uint256) {
        if (amount >= TIER3_THRESHOLD) return 4; // Gold+
        if (amount >= TIER2_THRESHOLD) return 3; // Gold
        if (amount >= TIER1_THRESHOLD) return 2; // Silver
        return 1;                                 // Bronze
    }

    function _getTierMultiplier(uint256 amount) internal pure returns (uint256) {
        if (amount >= TIER3_THRESHOLD) return TIER4_MULTIPLIER;
        if (amount >= TIER2_THRESHOLD) return TIER3_MULTIPLIER;
        if (amount >= TIER1_THRESHOLD) return TIER2_MULTIPLIER;
        return TIER1_MULTIPLIER;
    }

    function _tryAdvanceEpoch() internal {
        if (block.number >= epochStartBlock + EPOCH_DURATION) {
            _advanceEpoch();
        }
    }

    function _advanceEpoch() internal {
        epochTotalStaked[currentEpoch] = totalStaked;
        currentEpoch++;
        epochStartBlock = block.number;
        emit EpochAdvanced(currentEpoch, block.number, totalStaked);
    }

    // Accept plain ETH transfers (treated as reward pool funding)
    receive() external payable {
        rewardPool += msg.value;
    }
}
