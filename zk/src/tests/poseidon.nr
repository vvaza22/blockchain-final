use poseidon::poseidon::bn254::{hash_1, hash_2};

#[test]
fn test_poseidon() {
    let p_minus_one = Field::from(-1);
    println(f"p - 1 = {p_minus_one}");

    let zero_placeholder = Field::from(0x06ba262ceb5156c0fef18c1a9ed6f2d7063478e249a84a2e447efe50b59ac109);
    println(f"zero_placeholder = {zero_placeholder}");

    let x = Field::from(42);
    let y = Field::from(1337);

    let h1 = hash_1([x]);
    println(f"hash_1([42]) = {h1}");
    assert(h1 == Field::from(0x1b408dafebeddf0871388399b1e53bd065fd70f18580be5cdde15d7eb2c52743));

    let h2 = hash_2([x, y]);
    println(f"hash_2([42, 1337]) = {h2}");
    assert(h2 == Field::from(0x04b58f30c49617a1552bc3bda8822b7d8eea4ca6c34f3acb0f490c0e46c4d545));

    let h_zero = hash_1([Field::from(0)]);
    println(f"hash_1([0]) = {h_zero}");
    assert(h_zero == Field::from(0x2a09a9fd93c590c26b91effbb2499f07e8f7aa12e2b4940a3aed2411cb65e11c));

    let h_zeros = hash_2([Field::from(0), Field::from(0)]);
    println(f"hash_2([0, 0]) = {h_zeros}");
    assert(h_zeros == Field::from(0x2098f5fb9e239eab3ceac3f27b81e481dc3124d55ffed523a839ee8446b64864));

    let h_p_minus_one = hash_1([p_minus_one]);
    println(f"hash_1([p - 1]) = {h_p_minus_one}");
    assert(h_p_minus_one == Field::from(0x0771743e7ade0f56f51d16544f60059ba3029ba556d63697612900fe5f020b16));

    let h_p_minus_one_2 = hash_2([p_minus_one, p_minus_one]);
    println(f"hash_2([p - 1, p - 1]) = {h_p_minus_one_2}");
    assert(h_p_minus_one_2 == Field::from(0x2c6bd813a6338781378d8706cb82fd4216ab52b752ccd41564d7b98756a6e0fb));

    let h_zero_placeholder = hash_1([zero_placeholder]);
    println(f"hash_1([zero_placeholder]) = {h_zero_placeholder}");
    assert(h_zero_placeholder == Field::from(0x18bfd951dfdd2c062f381c772b91324c14505bf01f3c32020fa9c18df0a75f20));

    let h_zero_placeholder_2 = hash_2([zero_placeholder, zero_placeholder]);
    println(f"hash_2([zero_placeholder, zero_placeholder]) = {h_zero_placeholder_2}");
    assert(h_zero_placeholder_2 == Field::from(0x298bf8d39f171f9505873424572ad787f9bb4f19234a766ac623db0118d4f415));
}
