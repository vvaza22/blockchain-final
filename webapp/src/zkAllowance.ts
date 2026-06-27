import { Noir } from "@noir-lang/noir_js";
import type { CompiledCircuit } from "@noir-lang/noir_js";
import { UltraHonkBackend, Barretenberg } from "@aztec/bb.js";
import { del } from "idb-keyval";
import circuitJson from "@/circuits/allowance_zk_proof.json";

const circuit = circuitJson as unknown as CompiledCircuit;

let _noir: Noir | null = null;
let _backend: UltraHonkBackend | null = null;

// Clears stale CRS entries from a previous @aztec/bb.js version once.
// Older versions stored G1 points at 128 bytes/point; the current version
// expects 32 (compressed) or 64 (uncompressed), causing:
// "SrsInitSrs: invalid points_buf size … got 128".
// Update this key whenever @aztec/bb.js is upgraded.
// const CRS_CACHE_VERSION = "bb.js@4.3.1";
// async function clearStaleCrsCache() {
//   if (localStorage.getItem("crs_cache_version") === CRS_CACHE_VERSION) return;
//   await Promise.all([del("g1Data"), del("g2Data"), del("grumpkinG1Data")]);
//   localStorage.setItem("crs_cache_version", CRS_CACHE_VERSION);
// }

async function getInstances() {
  if (!_backend) {
    // await clearStaleCrsCache();
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
