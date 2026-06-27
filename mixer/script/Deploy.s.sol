// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {Script} from "forge-std/Script.sol";
import "forge-std/console2.sol";
import {MERKLE_TREE_HEIGHT} from "../src/Constants.sol";
import {
    GatedMixer
} from "../src/GatedMixer.sol";
import {
    HonkVerifier as DepositVerifier,
    Errors as DepositVerifierErrors
} from "../src/verifiers/membership_zk/Verifier.sol";
import {
    HonkVerifier as AllowanceVerifier,
    Errors as AllowanceVerifierErrors
} from "../src/verifiers/allowance_zk/Verifier.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        DepositVerifier depositVerifier = new DepositVerifier();
        AllowanceVerifier allowanceVerifier = new AllowanceVerifier();

        GatedMixer gatedMixer = new GatedMixer(
            MERKLE_TREE_HEIGHT,
            1 ether,
            address(depositVerifier),
            address(allowanceVerifier),
            true
        );

        console2.log("GatedMixer deployed at: ", address(gatedMixer));

        vm.stopBroadcast();
    }
}
