// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {GatedMixer, TreeHeightMustBeNonZero, TreeIsFull, InvalidDepositAmount, CommitmentAlreadyExists, Deposit} from "../src/GatedMixer.sol";
import {ZERO_PLACEHOLDER, MAX_FIELD, MERKLE_TREE_HEIGHT} from "../src/Constants.sol";
import "forge-std/console.sol";
import "../src/Helper.sol";

contract GatedMixerTest is Test {
    function test_Constructor() public {
        GatedMixer mixer;

        vm.expectRevert(TreeHeightMustBeNonZero.selector);
        mixer = new GatedMixer(0, 1 ether);

        mixer = new GatedMixer(1, 1 ether);
        assertEq(mixer.treeHeight(), 1);

        mixer = new GatedMixer(2, 1 ether);
        assertEq(mixer.treeHeight(), 2);

        mixer = new GatedMixer(MERKLE_TREE_HEIGHT, 1 ether);
        assertEq(mixer.treeHeight(), MERKLE_TREE_HEIGHT);
    }

    function test_InitialState() public {
        GatedMixer mixer = new GatedMixer(3, 1 ether);

        uint256 expected = ZERO_PLACEHOLDER;
        assertEq(mixer.getPlaceholder(0), expected);
        assertEq(mixer.getSibling(0), expected);

        expected = Helper.hash2(expected, expected);
        assertEq(mixer.getPlaceholder(1), expected);
        assertEq(mixer.getSibling(1), expected);

        expected = Helper.hash2(expected, expected);
        assertEq(mixer.getPlaceholder(2), expected);
        assertEq(mixer.getSibling(2), expected);
    }

    function test_InvalidDepositAmount() public {
        GatedMixer mixer = new GatedMixer(2, 1 ether);
        uint256 commitment = Helper.commitment(42, 1337);
        vm.deal(address(this), 2 ether);

        vm.expectRevert(
            abi.encodeWithSelector(InvalidDepositAmount.selector, 0, 1 ether)
        );
        mixer.deposit{value: 0}(commitment);

        vm.expectRevert(
            abi.encodeWithSelector(
                InvalidDepositAmount.selector,
                2 ether,
                1 ether
            )
        );
        mixer.deposit{value: 2 ether}(commitment);
    }

    function test_Deposit() public {
        GatedMixer mixer = new GatedMixer(2, 1 ether);
        assertEq(mixer.nextIndex(), 0);

        uint256 commitment0 = Helper.commitment(42, 1337);
        uint256 commitment0ZeroPair = Helper.hash2(
            commitment0,
            ZERO_PLACEHOLDER
        );
        uint256 zeroPair = Helper.hash2(ZERO_PLACEHOLDER, ZERO_PLACEHOLDER);
        uint256 expectedRoot0 = Helper.hash2(commitment0ZeroPair, zeroPair);
        vm.deal(address(this), 1 ether);
        vm.expectEmit(true, false, false, true);
        emit Deposit(commitment0, 0);
        mixer.deposit{value: 1 ether}(commitment0);
        assertEq(mixer.nextIndex(), 1);
        assertEq(mixer.merkleRoot(), expectedRoot0);
        assertEq(mixer.getSibling(0), commitment0);
        assertEq(mixer.getSibling(1), commitment0ZeroPair);

        uint256 commitment1 = Helper.commitment(43, 1338);
        uint256 commitment01Pair = Helper.hash2(commitment0, commitment1);
        uint256 expectedRoot1 = Helper.hash2(commitment01Pair, zeroPair);
        vm.deal(address(this), 1 ether);
        vm.expectEmit(true, false, false, true);
        emit Deposit(commitment1, 1);
        mixer.deposit{value: 1 ether}(commitment1);
        assertEq(mixer.nextIndex(), 2);
        assertEq(mixer.merkleRoot(), expectedRoot1);
        assertEq(mixer.getSibling(0), commitment0);
        assertEq(mixer.getSibling(1), commitment01Pair);

        uint256 commitment2 = Helper.commitment(44, 1339);
        uint256 commitment2ZeroPair = Helper.hash2(
            commitment2,
            ZERO_PLACEHOLDER
        );
        uint256 expectedRoot2 = Helper.hash2(
            commitment01Pair,
            commitment2ZeroPair
        );
        vm.deal(address(this), 1 ether);
        vm.expectEmit(true, false, false, true);
        emit Deposit(commitment2, 2);
        mixer.deposit{value: 1 ether}(commitment2);
        assertEq(mixer.nextIndex(), 3);
        assertEq(mixer.merkleRoot(), expectedRoot2);
        assertEq(mixer.getSibling(0), commitment2);
        assertEq(mixer.getSibling(1), commitment01Pair);

        uint256 commitment3 = Helper.commitment(45, 1340);
        uint256 commitment23Pair = Helper.hash2(commitment2, commitment3);
        uint256 expectedRoot3 = Helper.hash2(
            commitment01Pair,
            commitment23Pair
        );
        vm.deal(address(this), 1 ether);
        vm.expectEmit(true, false, false, true);
        emit Deposit(commitment3, 3);
        mixer.deposit{value: 1 ether}(commitment3);
        assertEq(mixer.nextIndex(), 4);
        assertEq(mixer.merkleRoot(), expectedRoot3);
        assertEq(mixer.getSibling(0), commitment2);
        assertEq(mixer.getSibling(1), commitment01Pair);

        uint256 commitment4 = Helper.commitment(46, 1341);
        vm.deal(address(this), 1 ether);
        vm.expectRevert(abi.encodeWithSelector(TreeIsFull.selector, 4));
        mixer.deposit{value: 1 ether}(commitment4);
    }

    function test_CommitmentAlreadyExists() public {
        GatedMixer mixer = new GatedMixer(2, 1 ether);
        uint256 commitment = Helper.commitment(42, 1337);
        vm.deal(address(this), 2 ether);

        mixer.deposit{value: 1 ether}(commitment);
        assertEq(mixer.nextIndex(), 1);

        vm.expectRevert(
            abi.encodeWithSelector(CommitmentAlreadyExists.selector, commitment)
        );
        mixer.deposit{value: 1 ether}(commitment);
    }
}
