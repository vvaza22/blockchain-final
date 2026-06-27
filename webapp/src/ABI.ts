export const ABI = [
  {
    type: "constructor",
    inputs: [
      {
        name: "_treeHeight",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "_denomination",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "_depositVerifier",
        type: "address",
        internalType: "address",
      },
      {
        name: "_allowanceVerifier",
        type: "address",
        internalType: "address",
      },
      {
        name: "_allowlistEnabled",
        type: "bool",
        internalType: "bool",
      },
    ],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "allow",
    inputs: [
      {
        name: "commitment",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "allowanceMerkleRoot",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "allowanceNextIndex",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "allowanceVerifier",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "address",
        internalType: "contract HonkVerifier",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "allowlistEnabled",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "bool",
        internalType: "bool",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "denomination",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "deposit",
    inputs: [
      {
        name: "commitment",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "pubMerkleRoot",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "pubNullifierHash",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "zkProof",
        type: "bytes",
        internalType: "bytes",
      },
    ],
    outputs: [],
    stateMutability: "payable",
  },
  {
    type: "function",
    name: "depositMerkleRoot",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "depositNextIndex",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "depositVerifier",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "address",
        internalType: "contract HonkVerifier",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getAllowanceSibling",
    inputs: [
      {
        name: "level",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getDepositSibling",
    inputs: [
      {
        name: "level",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getMerklePlaceholder",
    inputs: [
      {
        name: "level",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "owner",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "address",
        internalType: "address",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "treeHeight",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "withdraw",
    inputs: [
      {
        name: "pubMerkleRoot",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "pubNullifierHash",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "recipientAddress",
        type: "address",
        internalType: "address payable",
      },
      {
        name: "zkProof",
        type: "bytes",
        internalType: "bytes",
      },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "event",
    name: "Allowance",
    inputs: [
      {
        name: "commitment",
        type: "uint256",
        indexed: true,
        internalType: "uint256",
      },
      {
        name: "index",
        type: "uint256",
        indexed: false,
        internalType: "uint256",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "Deposit",
    inputs: [
      {
        name: "commitment",
        type: "uint256",
        indexed: true,
        internalType: "uint256",
      },
      {
        name: "index",
        type: "uint256",
        indexed: false,
        internalType: "uint256",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "Withdraw",
    inputs: [
      {
        name: "nullifierHash",
        type: "uint256",
        indexed: true,
        internalType: "uint256",
      },
      {
        name: "recipient",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "amount",
        type: "uint256",
        indexed: false,
        internalType: "uint256",
      },
    ],
    anonymous: false,
  },
  {
    type: "error",
    name: "AllowanceAlreadyExists",
    inputs: [
      {
        name: "commitment",
        type: "uint256",
        internalType: "uint256",
      },
    ],
  },
  {
    type: "error",
    name: "DepositAlreadyExists",
    inputs: [
      {
        name: "commitment",
        type: "uint256",
        internalType: "uint256",
      },
    ],
  },
  {
    type: "error",
    name: "DepositNotAllowed",
    inputs: [],
  },
  {
    type: "error",
    name: "InvalidDepositAmount",
    inputs: [
      {
        name: "sent",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "expected",
        type: "uint256",
        internalType: "uint256",
      },
    ],
  },
  {
    type: "error",
    name: "InvalidMerkleRoot",
    inputs: [
      {
        name: "merkleRoot",
        type: "uint256",
        internalType: "uint256",
      },
    ],
  },
  {
    type: "error",
    name: "InvalidProof",
    inputs: [],
  },
  {
    type: "error",
    name: "NullifierAlreadyUsed",
    inputs: [
      {
        name: "nullifier",
        type: "uint256",
        internalType: "uint256",
      },
    ],
  },
  {
    type: "error",
    name: "OnlyAdmin",
    inputs: [],
  },
  {
    type: "error",
    name: "OutOfBounds",
    inputs: [],
  },
  {
    type: "error",
    name: "TransferFailed",
    inputs: [
      {
        name: "recipient",
        type: "address",
        internalType: "address",
      },
      {
        name: "amount",
        type: "uint256",
        internalType: "uint256",
      },
    ],
  },
  {
    type: "error",
    name: "TreeHeightMustBeNonZero",
    inputs: [],
  },
  {
    type: "error",
    name: "TreeIsFull",
    inputs: [
      {
        name: "maxCommitments",
        type: "uint256",
        internalType: "uint256",
      },
    ],
  },
];
