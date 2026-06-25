// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "poseidon-solidity/PoseidonT2.sol";
import "poseidon-solidity/PoseidonT3.sol";

library Helper {
    function hash1(uint256 input) internal pure returns (uint256) {
        return PoseidonT2.hash([input]);
    }

    function hash2(uint256 left, uint256 right) internal pure returns (uint256) {
        return PoseidonT3.hash([left, right]);
    }

    function commitment(uint256 secret, uint256 nullifier) internal pure returns (uint256) {
        return hash2(secret, nullifier);
    }

    function nullifierHash(uint256 nullifier) internal pure returns (uint256) {
        return hash1(nullifier);
    }
}
