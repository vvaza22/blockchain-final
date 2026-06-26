// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ZERO_PLACEHOLDER} from "./Constants.sol";
import "./Helper.sol";
import {HonkVerifier} from "./verifiers/membership_zk/Verifier.sol";

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
    HonkVerifier public immutable verifier;

    uint256 public immutable treeHeight;
    uint256 public immutable denomination;

    uint256 public merkleRoot;
    uint256 public nextIndex;
    /* placeholders are the initial node values for each level in the Merkle tree */
    uint256[] internal placeholders;
    /* leftSibling array is used to recompute parent nodes when a new commitment is added */
    uint256[] internal leftSibling;
    /* prevent users from resubmitting the same commitment */
    mapping(uint256 => bool) internal commitments;
    /* prevent double spend */
    mapping(uint256 => bool) internal usedNullifiers;

    /*
     * @param _treeHeight Height of the Merkle tree measured in edges. Must be non-zero.
     * @param _denomination The denomination of the mixer. Must be a valid field element.
     * @param _verifier The address of the Honk verifier contract.
     */
    constructor(uint256 _treeHeight, uint256 _denomination, address _verifier) {
        if (_treeHeight == 0) revert TreeHeightMustBeNonZero();
        // TODO: check that denomination is a valid field element
        treeHeight = _treeHeight;
        denomination = _denomination;
        verifier = HonkVerifier(_verifier);
        placeholders = new uint256[](_treeHeight);
        leftSibling = new uint256[](_treeHeight);
        _precompute();
    }

    function getPlaceholder(uint256 level) external view returns (uint256) {
        if (level > treeHeight) revert OutOfBounds();
        return placeholders[level];
    }

    function getSibling(uint256 level) external view returns (uint256) {
        if (level > treeHeight) revert OutOfBounds();
        return leftSibling[level];
    }

    function _precompute() internal {
        uint256 current = ZERO_PLACEHOLDER;

        for (uint256 i = 0; i < treeHeight; i++) {
            placeholders[i] = current;
            leftSibling[i] = current;

            current = Helper.hash2(current, current);
        }

        merkleRoot = current;
    }

    function _insertCommitment(uint256 commitment) internal returns (uint256) {
        uint256 maxCommitments = 1 << treeHeight;
        if (nextIndex >= maxCommitments) revert TreeIsFull(maxCommitments);

        uint256 currentIndex = nextIndex;
        uint256 currentHash = commitment;

        uint256 left;
        uint256 right;

        for (uint256 level = 0; level < treeHeight; level++) {
            if (currentIndex % 2 == 0) {
                left = currentHash;
                right = placeholders[level];
                leftSibling[level] = currentHash;
            } else {
                left = leftSibling[level];
                right = currentHash;
            }
            currentHash = Helper.hash2(left, right);
            currentIndex /= 2;
        }

        merkleRoot = currentHash;
        return nextIndex++;
    }

    function isValidMerkleRoot(uint256 root) internal view returns (bool) {
        return root == merkleRoot;
    }

    function deposit(uint256 commitment) external payable {
        if (msg.value != denomination) revert InvalidDepositAmount(msg.value, denomination);
        if (commitments[commitment]) revert CommitmentAlreadyExists(commitment);
        commitments[commitment] = true;
        uint256 index = _insertCommitment(commitment);
        emit Deposit(commitment, index);
    }

    function withdraw(
        uint256 pubMerkleRoot,
        uint256 pubNullifierHash,
        address payable recipientAddress,
        bytes calldata zkProof
    ) external {
        if (!isValidMerkleRoot(pubMerkleRoot)) revert InvalidMerkleRoot(pubMerkleRoot);
        if (usedNullifiers[pubNullifierHash]) revert NullifierAlreadyUsed(pubNullifierHash);

        bytes32[] memory pubInputs = new bytes32[](3);
        pubInputs[0] = bytes32(pubMerkleRoot);
        pubInputs[1] = bytes32(pubNullifierHash);
        pubInputs[2] = bytes32(uint256(uint160(address(recipientAddress))));

        if (!verifier.verify(zkProof, pubInputs)) revert InvalidProof();

        // Reentrancy guard
        usedNullifiers[pubNullifierHash] = true;
        (bool success, ) = recipientAddress.call{value: denomination}("");
        if (!success) revert TransferFailed(recipientAddress, denomination);

        emit Withdraw(pubNullifierHash, recipientAddress, denomination);
    }
}
