// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

// Internal Imports
import {IAllocationExtension} from "contracts/strategies/extensions/allocate/IAllocationExtension.sol";
import {ISablierV2LockupLinear} from "v2-core/src/interfaces/ISablierV2LockupLinear.sol";
import {Broker, LockupLinear} from "v2-core/src/types/DataTypes.sol";
import {BaseStrategy} from "contracts/strategies/BaseStrategy.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Transfer} from "contracts/core/libraries/Transfer.sol";

abstract contract SablierAllocationExtension is BaseStrategy, IAllocationExtension {
    using Transfer for address;

    /// ================================
    /// =========== Errors =============
    /// ================================

    error OnlyERC20_ALLOWED_TOKENS();

    /// ================================
    /// =========== Events =============
    /// ================================

    event StreamDistributionStarted(
        address recipientAddress,
        uint256 amount,
        uint256 streamID
    );

    /// ================================
    /// ========== Storage =============
    /// ================================

    /// @notice Sablier lockup linear contract
    ISablierV2LockupLinear public lockupLinear;

    bool public cancelableStream;

    uint40 public streamingDuration;

    /// @notice See https://docs.sablier.com/concepts/protocol/fees#broker-fees
    Broker public broker;

    /// @notice The start time for allocations
    uint64 public allocationStartTime;
    /// @notice The end time for allocations
    uint64 public allocationEndTime;

    /// @notice Defines if the strategy is sending Metadata struct in the data parameter
    bool public isUsingAllocationMetadata;

    /// @notice token -> isAllowed
    mapping(address => bool) public allowedTokens;

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    /// @notice This initializes the Alocation Extension
    /// @dev This function MUST be called by the 'initialize' function in the strategy.
    /// @param _allowedTokens The allowed tokens
    /// @param _lockupLinear The Sablier lockup linear contract
    /// @param _cancelableStream Defines if the stream is cancelable
    /// @param _streamingDuration The streaming period
    /// @param _allocationStartTime The start time for the allocation period
    /// @param _allocationEndTime The end time for the allocation period
    /// @param _isUsingAllocationMetadata Defines if the strategy is sending Metadata struct in the data parameter
    function __SablierAllocationExtension_init(
        address[] memory _allowedTokens,
        address _lockupLinear,
        uint40 _streamingDuration,
        bool _cancelableStream,
        uint64 _allocationStartTime,
        uint64 _allocationEndTime,
        bool _isUsingAllocationMetadata
    ) internal virtual {
        if (_allowedTokens.length == 0) {
            // all tokens
            allowedTokens[address(0)] = true;
        } else {
            for (uint256 i; i < _allowedTokens.length; i++) {
                if (_allowedTokens[i] == Transfer.NATIVE) revert OnlyERC20_ALLOWED_TOKENS();
                allowedTokens[_allowedTokens[i]] = true;
            }
        }

        lockupLinear = ISablierV2LockupLinear(_lockupLinear);

        cancelableStream = _cancelableStream;

        streamingDuration = _streamingDuration;

        isUsingAllocationMetadata = _isUsingAllocationMetadata;

        _updateAllocationTimestamps(_allocationStartTime, _allocationEndTime);
    }

    /// ====================================
    /// =========== Modifiers ==============
    /// ====================================

    /// @notice Modifier to check if allocation has ended
    /// @dev Reverts if allocation has not ended
    modifier onlyAfterAllocation() {
        _checkOnlyAfterAllocation();
        _;
    }

    /// @notice Modifier to check if allocation is active
    /// @dev Reverts if allocation is not active
    modifier onlyActiveAllocation() {
        _checkOnlyActiveAllocation();
        _;
    }

    /// @notice Modifier to check if allocation has started
    /// @dev Reverts if allocation has started
    modifier onlyBeforeAllocation() {
        _checkBeforeAllocation();
        _;
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Checks if the allocator is valid
    /// @param _allocator The allocator address
    /// @return 'true' if the allocator is valid, otherwise 'false'
    function _isValidAllocator(address _allocator) internal view virtual returns (bool);

    /// @notice Returns TRUE if the token is allowed
    /// @param _token The token to check
    /// @return 'true' if the token is allowed, otherwise 'false'
    function _isAllowedToken(address _token) internal view virtual returns (bool) {
        // all tokens allowed
        if (allowedTokens[address(0)]) return true;

        if (allowedTokens[_token]) return true;

        return false;
    }

    /// @notice Sets the start and end dates for allocation.
    /// @dev The 'msg.sender' must be a pool manager.
    /// @param _allocationStartTime The start time for the allocation
    /// @param _allocationEndTime The end time for the allocation
    function _updateAllocationTimestamps(uint64 _allocationStartTime, uint64 _allocationEndTime) internal virtual {
        if (_allocationStartTime > _allocationEndTime) revert AllocationExtension_INVALID_ALLOCATION_TIMESTAMPS();

        allocationStartTime = _allocationStartTime;
        allocationEndTime = _allocationEndTime;

        emit AllocationTimestampsUpdated(_allocationStartTime, _allocationEndTime, msg.sender);
    }

    /// @dev Ensure the function is called before allocation start time
    function _checkBeforeAllocation() internal virtual {
        if (block.timestamp >= allocationStartTime) revert AllocationExtension_ALLOCATION_HAS_ALREADY_STARTED();
    }

    /// @dev Ensure the function is called during allocation times
    function _checkOnlyActiveAllocation() internal virtual {
        if (block.timestamp < allocationStartTime) revert AllocationExtension_ALLOCATION_NOT_ACTIVE();
        if (block.timestamp > allocationEndTime) revert AllocationExtension_ALLOCATION_NOT_ACTIVE();
    }

    /// @dev Ensure the function is called after allocation start time
    function _checkOnlyAfterAllocation() internal virtual {
        if (block.timestamp <= allocationEndTime) revert AllocationExtension_ALLOCATION_HAS_NOT_ENDED();
    }

    /// @notice Distribute the tokens to the recipient using Sablier Linear Lockup Stream contract
    /// @dev The '_sender' must be a pool manager and the allocation must have ended
    /// @param _recipientId The recipient ids
    /// @param _amount The amount to distribute
    function _startSingleStreamDistribution(
        address _recipientId,
        address _poolToken,
        uint256 _amount
    ) internal returns (uint256 streamID) {
        // Create the stream
        LockupLinear.CreateWithDurations memory params = LockupLinear.CreateWithDurations({
            sender: address(this),
            recipient: _recipientId,
            totalAmount: uint128(_amount),
            asset: IERC20(_poolToken),
            cancelable: cancelableStream,
            durations: LockupLinear.Durations(0, streamingDuration),
            broker: broker
        });

        // Approve the Sablier contract to spend the pool tokens
        IERC20(_poolToken).approve(address(lockupLinear), _amount);
        // Start the stream
        streamID = lockupLinear.createWithDurations(params);

        emit StreamDistributionStarted(_recipientId, _amount, streamID);
    }

    //  ====================================
    //  ==== External/Public Functions =====
    //  ====================================

    /// @notice Sets the start and end dates for allocation.
    /// @dev The 'msg.sender' must be a pool manager.
    /// @param _allocationStartTime The start time for the allocation
    /// @param _allocationEndTime The end time for the allocation
    function updateAllocationTimestamps(uint64 _allocationStartTime, uint64 _allocationEndTime)
        external
        virtual
        onlyPoolManager(msg.sender)
    {
        _updateAllocationTimestamps(_allocationStartTime, _allocationEndTime);
    }
}
