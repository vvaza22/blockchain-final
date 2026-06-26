use poseidon::poseidon::bn254::{hash_1, hash_2};

global MERKLE_TREE_HEIGHT: u32 = 20;
global ZERO_PLACEHOLDER: Field = 0x06ba262ceb5156c0fef18c1a9ed6f2d7063478e249a84a2e447efe50b59ac109;

fn main(
    secret: Field,
    nullifier: Field,
    siblings: [Field; MERKLE_TREE_HEIGHT],
    path: [Field; MERKLE_TREE_HEIGHT],
    pub_merkle_root: pub Field,
    pub_nullifier_hash: pub Field,
    depositor_address: pub Field,
) {
    let commitment = hash_2([secret, nullifier]);
    let nullifier_hash = hash_1([nullifier]);
    assert(nullifier_hash == pub_nullifier_hash);

    let mut current_hash = commitment;
    // I need to move up the merkle tree
    for i in 0..MERKLE_TREE_HEIGHT {
        // Sibling is the hash of the other child of the parent node
        let sibling = siblings[i];
        // 0 is left child, 1 is right child
        let elem_index = path[i];
        assert((elem_index == 0) | (elem_index == 1));

        if elem_index == 0 {
            current_hash = hash_2([current_hash, sibling]);
        } else {
            current_hash = hash_2([sibling, current_hash]);
        }
    }

    assert(current_hash == pub_merkle_root);

    // This is here just to avoid unused variable warnings
    let _ = depositor_address;
}

fn compute_placeholders() -> [Field; MERKLE_TREE_HEIGHT] {
    let mut placeholders: [Field; MERKLE_TREE_HEIGHT] = [0; MERKLE_TREE_HEIGHT];
    placeholders[0] = ZERO_PLACEHOLDER;
    for i in 1..MERKLE_TREE_HEIGHT {
        placeholders[i] = hash_2([placeholders[i - 1], placeholders[i - 1]]);
    }
    placeholders
}

#[test]
fn test_merkle_membership_proof_leaf_0() {
    let secret = Field::from(42);
    let nullifier = Field::from(1337);

    let commitment = hash_2([secret, nullifier]);
    println(f"commitment = \"{commitment}\"");

    let nullifier_hash = hash_1([nullifier]);
    println(f"nullifier_hash = \"{nullifier_hash}\"");

    let placeholders = compute_placeholders();
    let siblings = placeholders;
    println("siblings:");
    for i in 0..MERKLE_TREE_HEIGHT {
        let value = siblings[i];
        println(f"\"{value}\",");
    }

    // Pick the very first leaf node for this test
    let path: [Field; MERKLE_TREE_HEIGHT] = [0; MERKLE_TREE_HEIGHT];
    println("path:");
    for i in 0..MERKLE_TREE_HEIGHT {
        let printValue = path[i];
        println(f"\"{printValue}\",");
    }

    let mut merkle_root = commitment;
    for i in 0..MERKLE_TREE_HEIGHT {
        merkle_root = hash_2([merkle_root, siblings[i]]);
    }
    println(f"merkle_root = \"{merkle_root}\"");

    main(
        secret,
        nullifier,
        siblings,
        path,
        merkle_root,
        nullifier_hash,
        Field::from(0xdeadbeef),
    );
}

#[test]
fn test_merkle_membership_proof_leaf_1() {
    let secret0 = Field::from(42);
    let nullifier0 = Field::from(1337);
    let commitment0 = hash_2([secret0, nullifier0]);

    let secret1 = Field::from(43);
    let nullifier1 = Field::from(1338);
    let commitment1 = hash_2([secret1, nullifier1]);
    let nullifier_hash1 = hash_1([nullifier1]);

    let placeholders = compute_placeholders();
    let mut siblings = placeholders;
    siblings[0] = commitment0;

    // Pick the leaf with index 1
    let mut path_indices: [Field; MERKLE_TREE_HEIGHT] = [0; MERKLE_TREE_HEIGHT];
    path_indices[0] = 1;

    let mut merkleRoot = hash_2([commitment0, commitment1]);
    for i in 1..MERKLE_TREE_HEIGHT {
        merkleRoot = hash_2([merkleRoot, siblings[i]]);
    }

    main(
        secret1,
        nullifier1,
        siblings,
        path_indices,
        merkleRoot,
        nullifier_hash1,
        Field::from(0xdeadbeef),
    );
}

#[test]
fn test_merkle_membership_proof_leaf_2() {
    let secret0 = Field::from(42);
    let nullifier0 = Field::from(1337);
    let commitment0 = hash_2([secret0, nullifier0]);

    let secret1 = Field::from(43);
    let nullifier1 = Field::from(1338);
    let commitment1 = hash_2([secret1, nullifier1]);

    let secret2 = Field::from(44);
    let nullifier2 = Field::from(1339);
    let commitment2 = hash_2([secret2, nullifier2]);
    let nullifier_hash2 = hash_1([nullifier2]);

    let placeholders = compute_placeholders();
    let mut siblings = placeholders;
    let rootA = hash_2([commitment0, commitment1]);
    let rootB = hash_2([commitment2, placeholders[0]]);
    siblings[0] = placeholders[0];
    siblings[1] = rootA;

    // Pick the leaf with index 2
    let mut path: [Field; MERKLE_TREE_HEIGHT] = [0; MERKLE_TREE_HEIGHT];
    path[0] = 0;
    path[1] = 1;

    let mut merkleRoot = hash_2([rootA, rootB]);
    for i in 2..MERKLE_TREE_HEIGHT {
        merkleRoot = hash_2([merkleRoot, siblings[i]]);
    }

    main(
        secret2,
        nullifier2,
        siblings,
        path,
        merkleRoot,
        nullifier_hash2,
        Field::from(0xdeadbeef),
    );
}

#[test]
fn test_merkle_membership_proof_leaf_3() {
    let secret0 = Field::from(42);
    let nullifier0 = Field::from(1337);
    let commitment0 = hash_2([secret0, nullifier0]);

    let secret1 = Field::from(43);
    let nullifier1 = Field::from(1338);
    let commitment1 = hash_2([secret1, nullifier1]);

    let secret2 = Field::from(44);
    let nullifier2 = Field::from(1339);
    let commitment2 = hash_2([secret2, nullifier2]);

    let secret3 = Field::from(45);
    let nullifier3 = Field::from(1340);
    let commitment3 = hash_2([secret3, nullifier3]);
    let nullifier_hash3 = hash_1([nullifier3]);

    let placeholders = compute_placeholders();
    let mut siblings = placeholders;
    let rootA = hash_2([commitment0, commitment1]);
    let rootB = hash_2([commitment2, commitment3]);
    siblings[0] = commitment2;
    siblings[1] = rootA;

    // Pick the leaf with index 3
    let mut path: [Field; MERKLE_TREE_HEIGHT] = [0; MERKLE_TREE_HEIGHT];
    path[0] = 1;
    path[1] = 1;

    let mut merkleRoot = hash_2([rootA, rootB]);
    for i in 2..MERKLE_TREE_HEIGHT {
        merkleRoot = hash_2([merkleRoot, siblings[i]]);
    }

    main(
        secret3,
        nullifier3,
        siblings,
        path,
        merkleRoot,
        nullifier_hash3,
        Field::from(0xdeadbeef),
    );
}

#[test]
fn test_merkle_membership_proof_leaf_7() {
    let secret0 = Field::from(42);
    let nullifier0 = Field::from(1337);
    let commitment0 = hash_2([secret0, nullifier0]);

    let secret1 = Field::from(43);
    let nullifier1 = Field::from(1338);
    let commitment1 = hash_2([secret1, nullifier1]);

    let secret2 = Field::from(44);
    let nullifier2 = Field::from(1339);
    let commitment2 = hash_2([secret2, nullifier2]);

    let secret3 = Field::from(45);
    let nullifier3 = Field::from(1340);
    let commitment3 = hash_2([secret3, nullifier3]);

    let secret4 = Field::from(46);
    let nullifier4 = Field::from(1341);
    let commitment4 = hash_2([secret4, nullifier4]);

    let secret5 = Field::from(47);
    let nullifier5 = Field::from(1342);
    let commitment5 = hash_2([secret5, nullifier5]);

    let secret6 = Field::from(48);
    let nullifier6 = Field::from(1343);
    let commitment6 = hash_2([secret6, nullifier6]);

    let secret7 = Field::from(49);
    let nullifier7 = Field::from(1344);
    let commitment7 = hash_2([secret7, nullifier7]);
    let nullifier_hash7 = hash_1([nullifier7]);

    let placeholders = compute_placeholders();
    let mut siblings = placeholders;
    let rootA = hash_2([commitment0, commitment1]);
    let rootB = hash_2([commitment2, commitment3]);
    let rootC = hash_2([commitment4, commitment5]);
    let rootD = hash_2([commitment6, commitment7]);
    let rootAB = hash_2([rootA, rootB]);
    let rootCD = hash_2([rootC, rootD]);
    siblings[0] = commitment6;
    siblings[1] = rootC;
    siblings[2] = rootAB;

    // Pick the leaf with index 7
    let mut path: [Field; MERKLE_TREE_HEIGHT] = [0; MERKLE_TREE_HEIGHT];
    path[0] = 1;
    path[1] = 1;
    path[2] = 1;

    let mut merkleRoot = hash_2([rootAB, rootCD]);
    for i in 3..MERKLE_TREE_HEIGHT {
        merkleRoot = hash_2([merkleRoot, siblings[i]]);
    }

    main(
        secret7,
        nullifier7,
        siblings,
        path,
        merkleRoot,
        nullifier_hash7,
        Field::from(0xdeadbeef),
    );
}

#[test]
fn test_merkle_membership_proof_last_leaf() {
    let secret = Field::from(42);
    let nullifier = Field::from(1337);
    let commitment = hash_2([secret, nullifier]);
    let nullifier_hash = hash_1([nullifier]);

    let placeholders = compute_placeholders();
    let siblings = placeholders;

    // Pick the very last leaf node for this test
    let path: [Field; MERKLE_TREE_HEIGHT] = [1; MERKLE_TREE_HEIGHT];

    let mut merkleRoot = commitment;
    for i in 0..MERKLE_TREE_HEIGHT {
        merkleRoot = hash_2([siblings[i], merkleRoot]);
    }

    main(
        secret,
        nullifier,
        siblings,
        path,
        merkleRoot,
        nullifier_hash,
        Field::from(0xdeadbeef),
    );
}

#[test(should_fail)]
fn test_merkle_membership_proof_should_reject_invalid_root() {
    let secret = Field::from(42);
    let nullifier = Field::from(1337);

    let commitment = hash_2([secret, nullifier]);
    let nullifier_hash = hash_1([nullifier]);

    let placeholders = compute_placeholders();
    let siblings = placeholders;

    // Pick the very first leaf node for this test
    let path_indices: [Field; MERKLE_TREE_HEIGHT] = [0; MERKLE_TREE_HEIGHT];

    // Provide invalid merkle root
    let merkleRoot = hash_2([commitment, Field::from(0xdeadbeef)]);

    main(
        secret,
        nullifier,
        siblings,
        path_indices,
        merkleRoot,
        nullifier_hash,
        Field::from(0xdeadbeef),
    );
}

#[test(should_fail)]
fn test_merkle_membership_proof_should_reject_invalid_nullifier_hash() {
    let secret = Field::from(42);
    let nullifier = Field::from(1337);

    let commitment = hash_2([secret, nullifier]);
    let invalid_nullifier_hash = hash_1([0xdeadbeef]);

    let placeholders = compute_placeholders();
    let siblings = placeholders;

    // Pick the very first leaf node for this test
    let path_indices: [Field; MERKLE_TREE_HEIGHT] = [0; MERKLE_TREE_HEIGHT];

    let mut merkleRoot = commitment;
    for i in 0..MERKLE_TREE_HEIGHT {
        merkleRoot = hash_2([merkleRoot, siblings[i]]);
    }

    main(
        secret,
        nullifier,
        siblings,
        path_indices,
        merkleRoot,
        invalid_nullifier_hash,
        Field::from(0xdeadbeef),
    );
}

#[test(should_fail)]
fn test_merkle_membership_proof_should_reject_invalid_secret() {
    let secret = Field::from(42);
    let nullifier = Field::from(1337);
    let invalid_secret = Field::from(43);
    let commitment = hash_2([secret, nullifier]);
    let nullifier_hash = hash_1([nullifier]);

    let placeholders = compute_placeholders();
    let siblings = placeholders;

    // Pick the very first leaf node for this test
    let path_indices: [Field; MERKLE_TREE_HEIGHT] = [0; MERKLE_TREE_HEIGHT];

    let mut merkleRoot = commitment;
    for i in 0..MERKLE_TREE_HEIGHT {
        merkleRoot = hash_2([merkleRoot, siblings[i]]);
    }

    main(
        invalid_secret,
        nullifier,
        siblings,
        path_indices,
        merkleRoot,
        nullifier_hash,
        Field::from(0xdeadbeef),
    );
}

#[test(should_fail)]
fn test_merkle_membership_proof_should_reject_invalid_nullifier() {
    let secret = Field::from(42);
    let nullifier = Field::from(1337);
    let invalid_nullifier = Field::from(1338);
    let invalid_nullifier_hash = hash_1([invalid_nullifier]);
    let commitment = hash_2([secret, nullifier]);

    let placeholders = compute_placeholders();
    let siblings = placeholders;

    // Pick the very first leaf node for this test
    let path_indices: [Field; MERKLE_TREE_HEIGHT] = [0; MERKLE_TREE_HEIGHT];

    let mut merkleRoot = commitment;
    for i in 0..MERKLE_TREE_HEIGHT {
        merkleRoot = hash_2([merkleRoot, siblings[i]]);
    }

    main(
        secret,
        invalid_nullifier,
        siblings,
        path_indices,
        merkleRoot,
        invalid_nullifier_hash,
        Field::from(0xdeadbeef),
    );
}

#[test(should_fail)]
fn test_merkle_membership_proof_should_reject_invalid_path() {
    let secret = Field::from(42);
    let nullifier = Field::from(1337);

    let commitment = hash_2([secret, nullifier]);
    let nullifier_hash = hash_1([nullifier]);

    let placeholders = compute_placeholders();
    let siblings = placeholders;

    let mut path: [Field; MERKLE_TREE_HEIGHT] = [0; MERKLE_TREE_HEIGHT];
    // Point to a different leaf node
    path[0] = 1;

    let mut merkleRoot = commitment;
    for i in 0..MERKLE_TREE_HEIGHT {
        merkleRoot = hash_2([merkleRoot, siblings[i]]);
    }

    main(
        secret,
        nullifier,
        siblings,
        path,
        merkleRoot,
        nullifier_hash,
        Field::from(0xdeadbeef),
    );
}

#[test(should_fail)]
fn test_merkle_membership_proof_should_reject_invalid_path_index() {
    let secret = Field::from(42);
    let nullifier = Field::from(1337);

    let commitment = hash_2([secret, nullifier]);
    let nullifier_hash = hash_1([nullifier]);

    let placeholders = compute_placeholders();
    let siblings = placeholders;

    let mut path: [Field; MERKLE_TREE_HEIGHT] = [0; MERKLE_TREE_HEIGHT];
    // Value 2 is not even a valid index for a binary merkle tree
    path[0] = 2;

    let mut merkleRoot = commitment;
    for i in 0..MERKLE_TREE_HEIGHT {
        merkleRoot = hash_2([merkleRoot, siblings[i]]);
    }

    main(
        secret,
        nullifier,
        siblings,
        path,
        merkleRoot,
        nullifier_hash,
        Field::from(0xdeadbeef),
    );
}

#[test(should_fail)]
fn test_merkle_membership_proof_should_reject_invalid_sibling() {
    let secret0 = Field::from(42);
    let nullifier0 = Field::from(1337);
    let commitment0 = hash_2([secret0, nullifier0]);

    let secret1 = Field::from(43);
    let nullifier1 = Field::from(1338);
    let commitment1 = hash_2([secret1, nullifier1]);
    let nullifier_hash1 = hash_1([nullifier1]);

    let placeholders = compute_placeholders();
    let mut siblings = placeholders;
    // Tamper with the sibling hash
    siblings[0] = hash_2([commitment0, Field::from(0xdeadbeef)]);

    // Pick the leaf with index 1
    let mut path_indices: [Field; MERKLE_TREE_HEIGHT] = [0; MERKLE_TREE_HEIGHT];
    path_indices[0] = 1;

    let mut merkleRoot = hash_2([commitment0, commitment1]);
    for i in 1..MERKLE_TREE_HEIGHT {
        merkleRoot = hash_2([merkleRoot, siblings[i]]);
    }

    main(
        secret1,
        nullifier1,
        siblings,
        path_indices,
        merkleRoot,
        nullifier_hash1,
        Field::from(0xdeadbeef),
    );
}
