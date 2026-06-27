import type { Leaf } from "./types";
import { computeCommitment } from "./commitment";
import { computeHash1 } from "./hash1";
import { MERKLE_TREE_HEIGHT, ZERO_PLACEHOLDER } from "./constants";

async function computePlaceholders(): Promise<string[]> {
  const placeholders = [ZERO_PLACEHOLDER];
  for (let i = 1; i < MERKLE_TREE_HEIGHT; i++) {
    const result = await computeCommitment(
      placeholders[i - 1],
      placeholders[i - 1],
    );
    placeholders.push(result.toString());
  }
  return placeholders;
}

async function computeNextLevel(
  placeholders: string[],
  indexToLevel: Map<number, string>,
  level: number,
): Promise<Map<number, string>> {
  const result = new Map<number, string>();

  for (const i of indexToLevel.keys()) {
    const parentIdx = Math.floor(i / 2);
    if (result.has(parentIdx)) {
      continue;
    }
    const leftIndex = parentIdx * 2;
    const rightIndex = leftIndex + 1;

    const left = indexToLevel.get(leftIndex) ?? placeholders[level];
    const right = indexToLevel.get(rightIndex) ?? placeholders[level];
    const value = await computeCommitment(left, right);

    result.set(parentIdx, value.toString());
  }

  return result;
}

async function computeSiblingsAndPath(
  indexToLevel: Map<number, string>,
  placeholders: string[],
  initialIndex: number,
): Promise<{ merkleRoot: string; siblings: string[]; path: number[] }> {
  const siblings = [];
  const path = [];
  let curIndex = initialIndex;

  for (let level = 0; level < MERKLE_TREE_HEIGHT; level++) {
    // 0 is left, 1 is right
    const parity = curIndex % 2;
    const siblingIndex = parity ? curIndex - 1 : curIndex + 1;
    const sibling = indexToLevel.get(siblingIndex) ?? placeholders[level];

    siblings.push(sibling);
    path.push(parity);

    indexToLevel = await computeNextLevel(placeholders, indexToLevel, level);
    curIndex = Math.floor(curIndex / 2);
  }

  const merkleRoot = indexToLevel.get(0)!;
  return { merkleRoot, siblings, path };
}

// secret: Field,
// nullifier: Field,
// siblings: [Field; MERKLE_TREE_HEIGHT],
// path: [Field; MERKLE_TREE_HEIGHT],
// pub_merkle_root: pub Field,
// pub_nullifier_hash: pub Field,
// depositor_address: pub Field,
export async function walker(
  secret: string,
  nullifier: string,
  selectedUser: string,
  leaves: Leaf[],
) {
  const commitment = await computeCommitment(secret, nullifier);
  const commitmentBigInt = BigInt(commitment.toString());
  console.log("computed commitment:", commitment);

  const nullifierHash = await computeHash1(nullifier);
  console.log("computed nullifier hash:", nullifierHash);

  const placeholders = await computePlaceholders();

  let indexToLevel = new Map<number, string>();
  for (const leaf of leaves) {
    indexToLevel.set(leaf.index, leaf.commitment);
  }

  const leafLocation = leaves.find(
    (l) => BigInt(l.commitment) === commitmentBigInt,
  );
  if (!leafLocation) {
    throw new Error("Commitment not found in leaves");
  }

  const { merkleRoot, siblings, path } = await computeSiblingsAndPath(
    indexToLevel,
    placeholders,
    leafLocation.index,
  );

  return {
    secret,
    nullifier,
    siblings,
    path,
    pub_merkle_root: merkleRoot,
    pub_nullifier_hash: nullifierHash.toString(),
    depositor_address: selectedUser,
  };
}

// secret: Field,
// nullifier: Field,
// siblings: [Field; MERKLE_TREE_HEIGHT],
// path: [Field; MERKLE_TREE_HEIGHT],
// pub_merkle_root: pub Field,
// pub_nullifier_hash: pub Field,
// recipient_address: pub Field,
export async function walkerWithdraw(
  secret: string,
  nullifier: string,
  selectedUser: string,
  leaves: Leaf[],
) {
  const commitment = await computeCommitment(secret, nullifier);
  const commitmentBigInt = BigInt(commitment.toString());
  console.log("computed commitment:", commitment);

  const nullifierHash = await computeHash1(nullifier);
  console.log("computed nullifier hash:", nullifierHash);

  const placeholders = await computePlaceholders();

  let indexToLevel = new Map<number, string>();
  for (const leaf of leaves) {
    indexToLevel.set(leaf.index, leaf.commitment);
  }

  const leafLocation = leaves.find(
    (l) => BigInt(l.commitment) === commitmentBigInt,
  );
  if (!leafLocation) {
    throw new Error("Commitment not found in leaves");
  }

  const { merkleRoot, siblings, path } = await computeSiblingsAndPath(
    indexToLevel,
    placeholders,
    leafLocation.index,
  );

  return {
    secret,
    nullifier,
    siblings,
    path,
    pub_merkle_root: merkleRoot,
    pub_nullifier_hash: nullifierHash.toString(),
    recipient_address: selectedUser,
  };
}
