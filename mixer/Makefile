.PHONY: test format deploy

test:
	forge test --code-size-limit 50000

format:
	forge fmt

deploy:
	forge script script/Deploy.s.sol \
		--rpc-url http://127.0.0.1:8545 \
		--private-key $(KEY) \
		--broadcast
