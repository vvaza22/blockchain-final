// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {ZERO_PLACEHOLDER, MAX_FIELD} from "../src/Constants.sol";
import "poseidon-solidity/PoseidonT2.sol";
import "poseidon-solidity/PoseidonT3.sol";
import "forge-std/console.sol";

uint256 constant POSEIDON_HASH1 = 0x1b408dafebeddf0871388399b1e53bd065fd70f18580be5cdde15d7eb2c52743;
uint256 constant POSEIDON_HASH2 = 0x04b58f30c49617a1552bc3bda8822b7d8eea4ca6c34f3acb0f490c0e46c4d545;
uint256 constant POSEIDON_HASH_ZERO = 0x2a09a9fd93c590c26b91effbb2499f07e8f7aa12e2b4940a3aed2411cb65e11c;
uint256 constant POSEIDON_HASH_ZEROS = 0x2098f5fb9e239eab3ceac3f27b81e481dc3124d55ffed523a839ee8446b64864;
uint256 constant POSEIDON_HASH_P_MINUS_ONE = 0x0771743e7ade0f56f51d16544f60059ba3029ba556d63697612900fe5f020b16;
uint256 constant POSEIDON_HASH_P_MINUS_ONE_2 = 0x2c6bd813a6338781378d8706cb82fd4216ab52b752ccd41564d7b98756a6e0fb;
uint256 constant POSEIDON_HASH_ZERO_PLACEHOLDER = 0x18bfd951dfdd2c062f381c772b91324c14505bf01f3c32020fa9c18df0a75f20;
uint256 constant POSEIDON_HASH_ZERO_PLACEHOLDER_2 = 0x298bf8d39f171f9505873424572ad787f9bb4f19234a766ac623db0118d4f415;

contract PoseidonTest is Test {
    function test_hash1() public pure {
        uint256 result = PoseidonT2.hash([uint256(42)]);
        assertEq(result, POSEIDON_HASH1);
    }

    function test_hash2() public pure {
        uint256 result = PoseidonT3.hash([uint256(42), uint256(1337)]);
        assertEq(result, POSEIDON_HASH2);
    }

    function test_hash_zero() public pure {
        uint256 result = PoseidonT2.hash([uint256(0)]);
        assertEq(result, POSEIDON_HASH_ZERO);
    }

    function test_hash_zeros() public pure {
        uint256 result = PoseidonT3.hash([uint256(0), uint256(0)]);
        assertEq(result, POSEIDON_HASH_ZEROS);
    }

    function test_hash_p_minus_one() public pure {
        uint256 result = PoseidonT2.hash([uint256(MAX_FIELD - 1)]);
        assertEq(result, POSEIDON_HASH_P_MINUS_ONE);
    }

    function test_hash_p_minus_one_2() public pure {
        uint256 result = PoseidonT3.hash(
            [uint256(MAX_FIELD - 1), uint256(MAX_FIELD - 1)]
        );
        assertEq(result, POSEIDON_HASH_P_MINUS_ONE_2);
    }

    function test_hash_zero_placeholder() public pure {
        uint256 result = PoseidonT2.hash([ZERO_PLACEHOLDER]);
        console.logBytes32(bytes32(ZERO_PLACEHOLDER));
        console.logBytes32(bytes32(result));
        assertEq(result, POSEIDON_HASH_ZERO_PLACEHOLDER);
    }

    function test_hash_zero_placeholder_2() public pure {
        uint256 result = PoseidonT3.hash([ZERO_PLACEHOLDER, ZERO_PLACEHOLDER]);
        console.logBytes32(bytes32(ZERO_PLACEHOLDER));
        console.logBytes32(bytes32(result));
        assertEq(result, POSEIDON_HASH_ZERO_PLACEHOLDER_2);
    }
}
