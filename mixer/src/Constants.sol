// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/* MAX_FIELD value is taken from NOIR directly by printing -1 and adding 1 to it */
uint256 constant MAX_FIELD = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;
/* Zero leaves of the Merkle tree are filled with ZERO_PLACEHOLDER. */
uint256 constant ZERO_PLACEHOLDER = uint256(keccak256("mixer")) % MAX_FIELD;

uint256 constant MERKLE_TREE_HEIGHT = 20;
