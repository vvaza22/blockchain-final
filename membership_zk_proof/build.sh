nargo compile
bb write_vk -b ./target/membership_zk_proof.json --oracle_hash keccak -o ./target
bb write_solidity_verifier -k ./target/vk -o ./target/Verifier.sol
