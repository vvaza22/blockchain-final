import { Noir } from "@noir-lang/noir_js";
import type { CompiledCircuit } from "@noir-lang/noir_js";
import { UltraHonkBackend, Barretenberg } from "@aztec/bb.js";
import circuitJson from "@/circuits/allowance_zk_proof.json";

const circuit = circuitJson as unknown as CompiledCircuit;

let _noir: Noir | null = null;
let _backend: UltraHonkBackend | null = null;

async function getInstances() {
  if (!_backend) {
    const api = await Barretenberg.new();
    _noir = new Noir(circuit);
    _backend = new UltraHonkBackend(circuit.bytecode, api);
  }
  return { noir: _noir!, backend: _backend! };
}

export async function computeAllowanceProof(inputs) {
  const { noir, backend } = await getInstances();
  const { witness } = await noir.execute(inputs);
  const { proof, publicInputs } = await backend.generateProof(witness, {
    verifierTarget: "evm",
  });
  return { proof, publicInputs };
}
