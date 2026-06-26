.PHONY: compile proof test

compile:
	nargo compile
	bb write_vk -b ./target/membership_zk_proof.json --oracle_hash keccak -o ./target
	bb write_solidity_verifier -k ./target/vk -o ./target/Verifier.sol

# USAGE: make proof NAME=proof1
proof:
	nargo execute witness
	bb write_vk -b ./target/membership_zk_proof.json --oracle_hash keccak -o ./target
	bb prove -b ./target/membership_zk_proof.json -w ./target/witness.gz -k ./target/vk --oracle_hash keccak -o ./target
	cp ./target/proof ../mixer/test/data/$(NAME).bin

test:
	nargo test --show-output