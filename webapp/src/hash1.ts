import { Noir } from "@noir-lang/noir_js";
import circuit from "@/circuits/hash1_circuit.json";

const noir = new Noir(circuit);

export async function computeHash1(x: string) {
  const { returnValue } = await noir.execute({ x: x });
  return returnValue;
}
