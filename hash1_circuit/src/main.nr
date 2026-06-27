use poseidon::poseidon::bn254::hash_1;

fn main(x: Field) -> pub Field {
    hash_1([x])
}
