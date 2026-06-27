import { Noir } from "@noir-lang/noir_js";
import circuit from "@/circuits/commitment_circuit.json";

const noir = new Noir(circuit);

export async function computeCommitment(secret: string, nullifier: string) {
  const { returnValue } = await noir.execute({
    nullifier: nullifier,
    secret: secret,
  });
  return returnValue;
}
