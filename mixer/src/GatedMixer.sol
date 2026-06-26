// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ZERO_PLACEHOLDER} from "./Constants.sol";
import "./Helper.sol";
import {HonkVerifier as DepositVerifier} from "./verifiers/membership_zk/Verifier.sol";
import {HonkVerifier as AllowanceVerifier} from "./verifiers/membership_zk/Verifier.sol";

error TreeHeightMustBeNonZero();
error OutOfBounds();
error InvalidDepositAmount(uint256 sent, uint256 expected);
error TreeIsFull(uint256 maxCommitments);
error CommitmentAlreadyExists(uint256 commitment);
error NullifierAlreadyUsed(uint256 nullifier);
error InvalidMerkleRoot(uint256 merkleRoot);
error InvalidProof();
error TransferFailed(address recipient, uint256 amount);

event Deposit(uint256 indexed commitment, uint256 index);
event Withdraw(uint256 indexed nullifierHash, address indexed recipient, uint256 amount);

contract GatedMixer {
    DepositVerifier public immutable depositVerifier;
    AllowanceVerifier public immutable allowanceVerifier;

    /* the same tree height is used for both allowance and deposit Merkle trees. */
    uint256 public immutable treeHeight;
    uint256 public immutable denomination;

    /* placeholders are the initial node values for each level in the Merkle tree */
    uint256[] internal _merkleTreePlaceholders;

    /* Allowance Merkle Tree */
    uint256 public allowanceMerkleRoot;
    uint256 public allowanceNextIndex;
    uint256[] internal _allowanceLeftSibling;
    mapping(uint256 => bool) internal _allowanceCommitments;
    mapping(uint256 => bool) internal _allowanceUsedNullifiers;

    /* Deposit Merkle Tree */
    uint256 public depositMerkleRoot;
    uint256 public depositNextIndex;
    /* left sibling array is used to recompute parent nodes when a new commitment is added */
    uint256[] internal _depositLeftSibling;
    /* needed to prevent users from resubmitting the same commitment */
    mapping(uint256 => bool) internal _depositCommitments;
    /* needed to prevent double spend */
    mapping(uint256 => bool) internal _depositUsedNullifiers;

    /*
     * @param _treeHeight Height of the Merkle tree measured in edges. Must be non-zero.
     * @param _denomination The denomination of the mixer. Must be a valid field element.
     * @param _verifier The address of the Honk verifier contract.
     */
    constructor(uint256 _treeHeight, uint256 _denomination, address _depositVerifier, address _allowanceVerifier) {
        if (_treeHeight == 0) revert TreeHeightMustBeNonZero();
        // TODO: check that denomination is a valid field element
        treeHeight = _treeHeight;
        denomination = _denomination;
        depositVerifier = DepositVerifier(_depositVerifier);
        allowanceVerifier = AllowanceVerifier(_allowanceVerifier);
        _merkleTreePlaceholders = new uint256[](_treeHeight);
        _depositLeftSibling = new uint256[](_treeHeight);
        _allowanceLeftSibling = new uint256[](_treeHeight);
        _precompute();
    }

    function getPlaceholder(uint256 level) external view returns (uint256) {
        if (level > treeHeight) revert OutOfBounds();
        return _merkleTreePlaceholders[level];
    }

    function getSibling(uint256 level) external view returns (uint256) {
        if (level > treeHeight) revert OutOfBounds();
        return _depositLeftSibling[level];
    }

    function _precompute() internal {
        uint256 current = ZERO_PLACEHOLDER;

        for (uint256 i = 0; i < treeHeight; i++) {
            _merkleTreePlaceholders[i] = current;
            _depositLeftSibling[i] = current;
            _allowanceLeftSibling[i] = current;

            current = Helper.hash2(current, current);
        }

        depositMerkleRoot = current;
    }

    function _insertCommitment(uint256 commitment) internal returns (uint256) {
        uint256 maxCommitments = 1 << treeHeight;
        if (depositNextIndex >= maxCommitments) revert TreeIsFull(maxCommitments);

        uint256 currentIndex = depositNextIndex;
        uint256 currentHash = commitment;

        uint256 left;
        uint256 right;

        for (uint256 level = 0; level < treeHeight; level++) {
            if (currentIndex % 2 == 0) {
                left = currentHash;
                right = _merkleTreePlaceholders[level];
                _depositLeftSibling[level] = currentHash;
            } else {
                left = _depositLeftSibling[level];
                right = currentHash;
            }
            currentHash = Helper.hash2(left, right);
            currentIndex /= 2;
        }

        depositMerkleRoot = currentHash;
        return depositNextIndex++;
    }

    function isValidMerkleRoot(uint256 root) internal view returns (bool) {
        return root == depositMerkleRoot;
    }

    function deposit(uint256 commitment) external payable {
        // TODO: Add a protection against reusing the same nullifier with different secret.
        if (msg.value != denomination) revert InvalidDepositAmount(msg.value, denomination);
        if (_depositCommitments[commitment]) revert CommitmentAlreadyExists(commitment);
        _depositCommitments[commitment] = true;
        uint256 index = _insertCommitment(commitment);
        emit Deposit(commitment, index);
    }

    function withdraw(
        uint256 pubMerkleRoot,
        uint256 pubNullifierHash,
        address payable recipientAddress,
        bytes calldata zkProof
    ) external {
        if (!isValidMerkleRoot(pubMerkleRoot)) {
            revert InvalidMerkleRoot(pubMerkleRoot);
        }
        if (_depositUsedNullifiers[pubNullifierHash]) revert NullifierAlreadyUsed(pubNullifierHash);

        bytes32[] memory pubInputs = new bytes32[](3);
        pubInputs[0] = bytes32(pubMerkleRoot);
        pubInputs[1] = bytes32(pubNullifierHash);
        pubInputs[2] = bytes32(uint256(uint160(address(recipientAddress))));

        if (!depositVerifier.verify(zkProof, pubInputs)) revert InvalidProof();

        // Reentrancy guard
        _depositUsedNullifiers[pubNullifierHash] = true;
        (bool success,) = recipientAddress.call{value: denomination}("");
        if (!success) revert TransferFailed(recipientAddress, denomination);

        emit Withdraw(pubNullifierHash, recipientAddress, denomination);
    }
}
