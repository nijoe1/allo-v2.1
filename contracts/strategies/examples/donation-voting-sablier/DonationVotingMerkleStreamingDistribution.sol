// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

// External Imports
// External Libraries
import {MerkleProof} from "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
// Internal Imports
// Interfaces
import {IAllo} from "contracts/core/interfaces/IAllo.sol";
// Core Contracts
import {DonationVotingOffchainWithSablier} from "strategies/examples/donation-voting-sablier/DonationVotingOffchainWithSablier.sol";
// Internal Libraries
import {Metadata} from "contracts/core/libraries/Metadata.sol";
import {Transfer} from "contracts/core/libraries/Transfer.sol";

// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⢿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⡟⠘⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣾⣿⣿⣿⣿⣾⠻⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⡿⠀⠀⠸⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⢀⣠⣴⣴⣶⣶⣶⣦⣦⣀⡀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣿⡿⠃⠀⠙⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠁⠀⠀⠀⢻⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⡀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠘⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⠃⠀⠀⠀⠀⠈⢿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⣰⣿⣿⣿⡿⠋⠁⠀⠀⠈⠘⠹⣿⣿⣿⣿⣆⠀⠀⠀
// ⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡀⠀⠀
// ⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣟⠀⡀⢀⠀⡀⢀⠀⡀⢈⢿⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀
// ⠀⠀⣠⣿⣿⣿⣿⣿⣿⡿⠋⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⡿⢿⠿⠿⠿⠿⠿⠿⠿⠿⠿⢿⣿⣿⣿⣷⡀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠸⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠂⠀⠀
// ⠀⠀⠙⠛⠿⠻⠻⠛⠉⠀⠀⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣧⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢻⣿⣿⣿⣷⣀⢀⠀⠀⠀⡀⣰⣾⣿⣿⣿⠏⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣧⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠹⢿⣿⣿⣿⣿⣾⣾⣷⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠙⠋⠛⠙⠋⠛⠙⠋⠛⠙⠋⠃⠀⠀⠀⠀⠀⠀⠀⠀⠠⠿⠻⠟⠿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠟⠿⠟⠿⠆⠀⠸⠿⠿⠟⠯⠀⠀⠀⠸⠿⠿⠿⠏⠀⠀⠀⠀⠀⠈⠉⠻⠻⡿⣿⢿⡿⡿⠿⠛⠁⠀⠀⠀⠀⠀⠀
//                    allo.gitcoin.co

/// @title Donation Voting Strategy with off-chain setup
/// @notice Strategy that allows allocations in multiple tokens to accepted recipient. The actual payouts are set
/// by the pool manager.
contract DonationVotingMerkleSteamingDistribution is DonationVotingOffchainWithSablier {
    using Transfer for address;

    /// ===============================
    /// ========== Events =============
    /// ===============================

    /// @notice Emitted when the distribution has been updated with a new merkle root or metadata
    /// @param merkleRoot The merkle root of the distribution
    /// @param metadata The metadata of the distribution
    event DistributionUpdated(bytes32 merkleRoot, Metadata metadata);

    /// ================================
    /// ========== Errors ==============
    /// ================================

    /// @notice Thrown when the merkle root is attempted to be updated but the distribution is ongoing
    error DonationVotingMerkleDistribution_DistributionAlreadyStarted();

    /// @notice Thrown when distribution is invoked but the merkle root has not been set yet
    error DonationVotingMerkleDistribution_MerkleRootNotSet();

    /// @notice Thrown when distribution is attempted twice for the same 'index'
    /// @param _index The index for which a repeated distribution was attempted
    error DonationVotingMerkleDistribution_AlreadyDistributed(uint256 _index);

    /// ================================
    /// ========== Struct ==============
    /// ================================

    /// @notice Stores the details of the distribution.
    /// @param index The index in the merkle tree
    /// @param recipientId The id of the recipient
    /// @param amount The amount the should be distributed to the recipient
    /// @param merkleProof The merkle proof
    struct Distribution {
        uint256 index;
        address recipientId;
        uint256 amount;
        bytes32[] merkleProof;
    }

    /// ================================
    /// ========== Storage =============
    /// ================================

    /// @notice Metadata containing the distribution data.
    Metadata public distributionMetadata;

    /// @notice Flag to indicate whether the distribution has started or not.
    bool public distributionStarted;

    /// @notice The merkle root of the distribution will be set by the pool manager.
    bytes32 public merkleRoot;

    /// @notice This is a packed array of booleans to keep track of claims distributed.
    /// @dev _distributedBitMap[0] is the first row of the bitmap and allows to store 256 bits to describe
    /// the status of 256 claims
    mapping(uint256 => uint256) internal _distributedBitMap;

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    /// @notice Constructor for the Donation Voting Offchain strategy
    /// @param _allo The 'Allo' contract
    /// @param _directTransfer false if allocations must be manually claimed, true if they are sent during allocation.
    constructor(address _allo, bool _directTransfer)
        DonationVotingOffchainWithSablier(_allo, "DonationVotingMerkleSablierStreamingDistribution", _directTransfer)
    {}

    /// ===============================
    /// ======= External/Custom =======
    /// ===============================

    /// @notice Invoked by round operator to update the merkle root and distribution Metadata.
    /// @param _data The data to be decoded
    /// @custom:data (bytes32 _merkleRoot, Metadata _distributionMetadata)
    function setPayout(bytes memory _data) external virtual override onlyPoolManager(msg.sender) onlyAfterAllocation {
        // The merkleRoot can only be updated before the distribution has started
        if (distributionStarted) revert DonationVotingMerkleDistribution_DistributionAlreadyStarted();

        (bytes32 _merkleRoot, Metadata memory _distributionMetadata) = abi.decode(_data, (bytes32, Metadata));

        merkleRoot = _merkleRoot;
        distributionMetadata = _distributionMetadata;

        emit DistributionUpdated(_merkleRoot, _distributionMetadata);
    }

    /// @notice Utility function to check if distribution is done.
    /// @dev This function doesn't change the state even if it is not marked as 'view'
    /// @param _index index of the distribution
    /// @return 'true' if distribution is completed, otherwise 'false'
    function hasBeenDistributed(uint256 _index) external returns (bool) {
        return _distributed(_index, false);
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Distributes funds (tokens) to recipients.
    /// @param _recipientIds NOT USED
    /// @param _data Data to be decoded
    /// @custom:data (Distribution[] _distributions)
    /// @param _sender The address of the sender
    function _distribute(address[] memory _recipientIds, bytes memory _data, address _sender)
        internal
        virtual
        override
        onlyAfterAllocation
    {
        if (merkleRoot == bytes32(0)) revert DonationVotingMerkleDistribution_MerkleRootNotSet();

        if (!distributionStarted) distributionStarted = true;

        // Loop through the distributions and distribute the funds
        Distribution[] memory distributions = abi.decode(_data, (Distribution[]));
        IAllo.Pool memory pool = _ALLO.getPool(_poolId);
        for (uint256 i; i < distributions.length; i++) {
            _distributeSingle(distributions[i], pool.token, _sender);
        }
    }

    /// @notice Check if the distribution has been distributed.
    /// @param _index index of the distribution
    /// @param _set if 'true' sets the '_distributedBitMap' index to 'true', otherwise it is left unmodified
    /// @return 'true' if the distribution has been distributed, otherwise 'false'
    function _distributed(uint256 _index, bool _set) internal returns (bool) {
        uint256 wordIndex = _index / 256;
        uint256 distributedWord = _distributedBitMap[wordIndex];

        uint256 bitIndex = _index % 256;
        // Get the mask by shifting 1 to the left of the 'bitIndex'
        uint256 mask = (1 << bitIndex);

        // Set the 'bitIndex' of 'distributedWord' to 1
        if (_set) _distributedBitMap[wordIndex] = distributedWord | (1 << bitIndex);

        // Return 'true' if the 'distributedWord' was 1 at 'bitIndex'
        return distributedWord & mask == mask;
    }

    /// @notice Distribute funds to recipient.
    /// @dev Emits a 'Distributed()' event per distributed recipient
    /// @param _distribution Distribution to be distributed
    /// @param _poolToken Token address of the strategy
    /// @param _sender The address of the sender
    function _distributeSingle(Distribution memory _distribution, address _poolToken, address _sender) internal {
        if (!_isAcceptedRecipient(_distribution.recipientId)) revert RecipientsExtension_RecipientNotAccepted();

        // Generate the node that will be verified in the 'merkleRoot'
        bytes32 _node = keccak256(abi.encode(_distribution.index, _distribution.recipientId, _distribution.amount));

        // Validate the distribution and transfer the funds to the recipient, otherwise skip
        if (MerkleProof.verify(_distribution.merkleProof, merkleRoot, _node)) {
            if (_distributed(_distribution.index, true)) {
                revert DonationVotingMerkleDistribution_AlreadyDistributed(_distribution.index);
            }
            _poolAmount -= _distribution.amount;

            address _recipientAddress = _recipients[_distribution.recipientId].recipientAddress;
            
            _startSingleStreamDistribution(_distribution.recipientId, _poolToken, _distribution.amount);

            emit Distributed(_distribution.recipientId, abi.encode(_recipientAddress, _distribution.amount, _sender));
        }
    }
}
