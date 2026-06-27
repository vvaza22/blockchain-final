import { useState, useEffect } from "react";
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
import { walker, walkerWithdraw } from "./walker";
import { CONTRACT_ADDRESS } from "./constants";
import { computeDepositProof } from "./zkDeposit";

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

async function doWithdraw(
  pubMerkleRoot: string,
  pubNullifierHash: string,
  recipientAddress: string,
  proofHex: string,
) {
  console.log(
    "Do withdraw with params: ",
    pubMerkleRoot,
    pubNullifierHash,
    recipientAddress,
    proofHex,
  );

  // uint256 pubMerkleRoot,
  // uint256 pubNullifierHash,
  // address payable recipientAddress,
  // bytes calldata zkProof
  const hash = await adminClient.writeContract({
    address: CONTRACT_ADDRESS,
    abi: ABI,
    functionName: "withdraw",
    args: [pubMerkleRoot, pubNullifierHash, recipientAddress, proofHex],
  });

  const receipt = await pubClient.waitForTransactionReceipt({ hash });
  console.log("WITHDRAW, status:", receipt.status);

  return receipt;
}

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

async function generateProofAndWithdraw(
  depositSecret: string,
  depositNullifier: string,
  selectedUser: string,
) {
  const leaves = await getDeposits();
  console.log("deposit leaves:", leaves);

  const args = await walkerWithdraw(
    depositSecret,
    depositNullifier,
    selectedUser,
    leaves,
  );
  console.log("generated withdraw proof args:", args);

  const proof = await computeDepositProof(args);
  console.log("generated deposit proof:", proof);

  // uint256 pubMerkleRoot,
  // uint256 pubNullifierHash,
  // address payable recipientAddress,
  // bytes calldata zkProof
  await doWithdraw(
    args["pub_merkle_root"],
    args["pub_nullifier_hash"],
    selectedUser,
    toHex(proof),
  );
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

  const hash = await adminClient.writeContract({
    address: CONTRACT_ADDRESS,
    abi: ABI,
    functionName: "allow",
    args: [BigInt(commitment)],
  });

  const receipt = await pubClient.waitForTransactionReceipt({ hash });
  console.log("ALLOW, status:", receipt.status);

  return receipt;
}

function toHexString(value: bigint): string {
  return "0x" + value.toString(16);
}

async function getDeposits() {
  const logs = await pubClient.getLogs({
    address: CONTRACT_ADDRESS,
    event: parseAbiItem(
      "event Deposit(uint256 indexed commitment, uint256 index)",
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

  console.log("deposits:", leaves);

  return leaves;
}

async function getWithdraws() {
  const logs = await pubClient.getLogs({
    address: CONTRACT_ADDRESS,
    event: parseAbiItem(
      "event Withdraw(uint256 indexed nullifierHash, address indexed recipient, uint256 amount)",
    ),
    fromBlock: 0n,
    toBlock: "latest",
  });

  const result = logs.map((log) => ({
    nullifierHash: toHexString(log.args.nullifierHash!),
  }));

  console.log("withdraws:", result);

  return result;
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
  const [allowanceList, setAllowanceList] = useState<string[]>([]);

  const [depositSecret, setDepositSecret] = useState("");
  const [depositNullifier, setDepositNullifier] = useState("");
  const [depositCommitment, setDepositCommitment] = useState("");
  const [depositList, setDepositList] = useState<string[]>([]);

  const [allowCommitment, setAllowCommitment] = useState("");
  const [selectedUser, setSelectedUser] = useState("");

  const [withdrawUser, setWithdrawUser] = useState("");
  const [withdrawList, setWithdrawList] = useState<string[]>([]);

  useEffect(() => {
    const fetchAllowances = async () => {
      const alList = await getAllowances();
      setAllowanceList(alList.map((l) => l.commitment));
    };

    const fetchDeposits = async () => {
      const depList = await getDeposits();
      setDepositList(depList.map((l) => l.commitment));
    };

    const fetchWithdraws = async () => {
      const wdList = await getWithdraws();
      setWithdrawList(wdList.map((l) => l.nullifierHash));
    };

    fetchAllowances();
    fetchDeposits();
    fetchWithdraws();
  }, []);

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
    const alList = await getAllowances();
    setAllowanceList(alList.map((l) => l.commitment));
  };

  const handleDeposit = async () => {
    await generateProofAndDeposit(
      allowanceSecret,
      allowanceNullifier,
      depositSecret,
      depositNullifier,
      selectedUser,
    );
    const depList = await getDeposits();
    setDepositList(depList.map((l) => l.commitment));
  };

  const handleWithdraw = async () => {
    await generateProofAndWithdraw(
      depositSecret,
      depositNullifier,
      withdrawUser,
    );
    const wdList = await getWithdraws();
    setWithdrawList(wdList.map((l) => l.nullifierHash));
  };

  return (
    <div className="w-full">
      <div className="p-2">
        <h3>Admin Only</h3>
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

        <div className="p-2">
          {allowanceList.length > 0 && (
            <div>
              <h5>Allowances:</h5>
              <ul>
                {allowanceList.map((commitment, index) => (
                  <li key={index}>{commitment}</li>
                ))}
              </ul>
            </div>
          )}
        </div>

        <h3>User Space</h3>
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
            onClick={() => {
              handleDeposit();
            }}
            variant="outline"
          >
            DEPOSIT 1 ETH
          </Button>
        </div>

        <div className="p-2">
          {depositList.length > 0 && (
            <div>
              <h5>Deposits:</h5>
              <ul>
                {depositList.map((commitment, index) => (
                  <li key={index}>{commitment}</li>
                ))}
              </ul>
            </div>
          )}
        </div>

        <div className="p-2 flex flex-col gap-2">
          <Select>
            <SelectTrigger className="w-full">
              <SelectValue placeholder="Select Withdraw user" />
            </SelectTrigger>
            <SelectContent>
              <SelectGroup>
                {users.map((user, index) => (
                  <SelectItem
                    key={index}
                    value={user.address}
                    onClick={() => {
                      console.log("selected withdraw user:", user.address);
                      setWithdrawUser(user.address);
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
          <Button onClick={() => handleWithdraw()} variant="outline">
            WITHDRAW 1 ETH
          </Button>
        </div>

        <div className="p-2">
          {withdrawList.length > 0 && (
            <div>
              <h5>Withdraws:</h5>
              <ul>
                {withdrawList.map((nullifierHash, index) => (
                  <li key={index}>{nullifierHash}</li>
                ))}
              </ul>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default App;
