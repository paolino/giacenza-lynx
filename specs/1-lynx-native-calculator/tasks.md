# Tasks — issue #1 / slice S1

- [x] T001 Scaffold flake (`devShell` + `.#giacenza-lynx-bundle`
      via `ghcNative` + `mkLynxBundle`), cabal package,
      fourmolu.yaml, justfile, LICENSE, `.gitignore` extras
- [x] T002 M-TYPES (copy from giacenza-miso)
- [x] T003 M-PARSE + RED/GREEN proofs for parse/error invariants
- [x] T004 M-COMPUTE + RED/GREEN proofs for compute invariants
- [x] T005 M-APP miso-native UI (textarea, column cycle, format
      toggle, table, error, stable ids)
- [x] T006 Flake bundle `main.lynx.bundle` +
      `main.lynx.bundle.sha256` via `just bundle` / `nix build`
- [x] T007 Gate inspector: pair, sha256, non-stub size, compiled
      marker or ≥ 1 MiB; record file(1) + size in the PR
- [x] T008 README: how to `just unit` and `nix build` the bundle;
      PR body includes FR-011 native-build notes and the device
      residual

Slice S1 closes when T001–T008 are checked and the auditor has
reported on the candidate.
