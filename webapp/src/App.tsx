import { useState } from "react";
import {
  createWalletClient,
  createPublicClient,
  http,
  toHex,
  parseEther,
} from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { parseAbiItem } from "viem";
import { foundry } from "viem/chains";
import { cn } from "@/shadcn/lib/utils";
import { Input } from "@/shadcn/components/ui/input";
import { Button } from "./shadcn/components/ui/button";
import { ABI } from "./ABI";
import { computeCommitment } from "./commitment";
import { computeHash1 } from "./hash1";
import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/shadcn/components/ui/select";
import { computeAllowanceProof } from "./zkAllowance";
import { walker } from "./walker";
import { CONTRACT_ADDRESS } from "./constants";

const admin = privateKeyToAccount(
  "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
);

const users = [
  "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d",
  "0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a",
  "0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6",
  "0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a",
].map((privateKey) => privateKeyToAccount(privateKey as `0x${string}`));

const pubKeyToUser = new Map(users.map((u) => [String(u.address), u]));

console.log(
  "users:",
  users.map((u) => u.address),
);

const adminClient = createWalletClient({
  account: admin,
  chain: foundry,
  transport: http("http://127.0.0.1:8545"),
});

const pubClient = createPublicClient({
  chain: foundry,
  transport: http("http://127.0.0.1:8545"),
});

async function makeDeposit(
  newCommitment: string,
  pubMerkleRoot: string,
  pubNullifierHash: string,
  proofHex: string,
  userPubKey: string,
) {
  //   function deposit(
  //     uint256 commitment,
  //     // Caller needs to prove they are allowed to deposit
  //     uint256 pubMerkleRoot,
  //     uint256 pubNullifierHash,
  //     bytes calldata zkProof
  // )
  //     external
  //     payable
  console.log(
    "Making a deposit with params: ",
    newCommitment,
    pubMerkleRoot,
    pubNullifierHash,
    proofHex,
    userPubKey,
  );
  const asUser = pubKeyToUser.get(userPubKey)!;
  console.log("using user account:", asUser.address);
  const client = createWalletClient({
    account: asUser,
    chain: foundry,
    transport: http("http://127.0.0.1:8545"),
  });

  const hash = await client.writeContract({
    address: CONTRACT_ADDRESS,
    abi: ABI,
    functionName: "deposit",
    args: [newCommitment, pubMerkleRoot, pubNullifierHash, proofHex],
    value: parseEther("1"),
  });

  const receipt = await pubClient.waitForTransactionReceipt({ hash });
  console.log("DEPOSIT, status:", receipt.status);

  return receipt;
}

async function generateProofAndDeposit(
  allowanceSecret: string,
  allowanceNullifier: string,
  depositSecret: string,
  depositNullifier: string,
  selectedUser: string,
) {
  const leaves = await getAllowances();
  const args = await walker(
    allowanceSecret,
    allowanceNullifier,
    selectedUser,
    leaves,
  );
  console.log("generated allowance proof args:", args);

  const { proof, publicInputs } = await computeAllowanceProof(args);
  console.log("generated allowance proof:", proof);
  console.log("generated allowance proof public inputs:", publicInputs);

  const depositCommitment = await computeCommitment(
    depositSecret,
    depositNullifier,
  );
  console.log("generated deposit commitment:", depositCommitment);

  await makeDeposit(
    depositCommitment.toString(),
    args["pub_merkle_root"],
    args["pub_nullifier_hash"],
    toHex(proof),
    selectedUser,
  );
}

async function sendAllowRequest(commitment: string) {
  commitment = commitment.trim();
  console.log("sending allow request for allowance commitment:", commitment);
  try {
    const hash = await adminClient.writeContract({
      address: CONTRACT_ADDRESS,
      abi: ABI,
      functionName: "allow",
      args: [BigInt(commitment)],
    });

    console.log("tx sent:", hash);

    const receipt = await pubClient.waitForTransactionReceipt({ hash });
    console.log("mined, status:", receipt.status);

    return receipt;
  } catch (err) {
    console.error("allow failed:", err);
    throw err;
  }
}

function toHexString(value: bigint): string {
  return "0x" + value.toString(16);
}

async function getAllowances() {
  const logs = await pubClient.getLogs({
    address: CONTRACT_ADDRESS,
    event: parseAbiItem(
      "event Allowance(uint256 indexed commitment, uint256 index)",
    ),
    fromBlock: 0n,
    toBlock: "latest",
  });

  const leaves = logs.map((log) => ({
    commitment: toHexString(log.args.commitment!),
    index: Number(log.args.index),
  }));

  // Sort by indices in an ascending order
  leaves.sort((a, b) => a.index - b.index);

  console.log("allowances:", leaves);

  return leaves;
}

function App() {
  const [allowanceSecret, setAllowanceSecret] = useState("");
  const [allowanceNullifier, setAllowanceNullifier] = useState("");
  const [allowanceCommitment, setAllowanceCommitment] = useState("");

  const [depositSecret, setDepositSecret] = useState("");
  const [depositNullifier, setDepositNullifier] = useState("");
  const [depositCommitment, setDepositCommitment] = useState("");

  const [allowCommitment, setAllowCommitment] = useState("");
  const [selectedUser, setSelectedUser] = useState("");

  const handleGenerateAllowanceCommitment = async (
    secret: string,
    nullifier: string,
  ) => {
    const commitment = await computeCommitment(secret, nullifier);
    console.log("generated allowance commitment:", commitment);
    setAllowanceCommitment(commitment.toString());
  };

  const handleGenerateDepositCommitment = async (
    secret: string,
    nullifier: string,
  ) => {
    const commitment = await computeCommitment(secret, nullifier);
    console.log("generated deposit commitment:", commitment);
    setDepositCommitment(commitment.toString());
  };

  const handleAllow = async () => {
    await sendAllowRequest(allowCommitment);
    await getAllowances();
  };

  return (
    <div className="w-full">
      <div className="p-2">
        <div className="p-2">
          <div className="flex flex-row gap-2">
            <Input
              placeholder="Type in commitment generated by a trusted user"
              onChange={(e) => {
                setAllowCommitment(e.target.value);
              }}
            />
            <Button variant="outline" onClick={handleAllow}>
              Add Allowance
            </Button>
          </div>
        </div>

        <div className="p-2 flex flex-col gap-2">
          <Select>
            <SelectTrigger className="w-full">
              <SelectValue placeholder="Select user" />
            </SelectTrigger>
            <SelectContent>
              <SelectGroup>
                {users.map((user, index) => (
                  <SelectItem
                    key={index}
                    value={user.address}
                    onClick={() => {
                      console.log("selected user:", user.address);
                      setSelectedUser(user.address);
                    }}
                  >
                    {user.address}
                  </SelectItem>
                ))}
              </SelectGroup>
            </SelectContent>
          </Select>
        </div>

        <div className="p-2 flex flex-col gap-2">
          <div className="flex flex-row gap-2">
            <Input
              placeholder="Allowance Secret"
              onChange={(e) => {
                setAllowanceSecret(e.target.value);
              }}
            />
            <Input
              placeholder="Allowance Nullifier"
              onChange={(e) => {
                setAllowanceNullifier(e.target.value);
              }}
            />
            <Button
              variant="outline"
              onClick={() =>
                handleGenerateAllowanceCommitment(
                  allowanceSecret,
                  allowanceNullifier,
                )
              }
            >
              Generate Allowance Commitment
            </Button>
          </div>
          <span>Allowance Commitment: {allowanceCommitment}</span>
        </div>

        <div className="p-2 flex flex-col gap-2">
          <div className="flex flex-row gap-2">
            <Input
              placeholder="Deposit Secret"
              onChange={(e) => {
                setDepositSecret(e.target.value);
              }}
            />
            <Input
              placeholder="Deposit Nullifier"
              onChange={(e) => {
                setDepositNullifier(e.target.value);
              }}
            />
            <Button
              variant="outline"
              onClick={() => {
                handleGenerateDepositCommitment(
                  depositSecret,
                  depositNullifier,
                );
              }}
            >
              Generate Deposit Commitment
            </Button>
          </div>
          <span>Deposit Commitment: {depositCommitment}</span>
        </div>

        <div className="p-2 flex flex-col gap-2">
          <Button
            onClick={() =>
              generateProofAndDeposit(
                allowanceSecret,
                allowanceNullifier,
                depositSecret,
                depositNullifier,
                selectedUser,
              )
            }
            variant="outline"
          >
            DEPOSIT 1 ETH
          </Button>
        </div>
      </div>
    </div>
  );
}

export default App;
