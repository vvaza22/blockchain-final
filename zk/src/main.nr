mod tests;

use poseidon::poseidon::bn254::hash_1;

fn main(
    x: Field,
    y: pub Field,
) {
    assert(hash_1([x]) == y);
}

#[test]
fn test_match() {
    let x = Field::from(123);
    let y = hash_1([x]);
    main(x, y);
}

#[test(should_fail)]
fn test_mismatch() {
    let x = Field::from(123);
    let x1 = Field::from(234);
    let y = hash_1([x1]);
    main(x, y);
}
