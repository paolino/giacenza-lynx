# Plan — giacenza miso-native / LynxJS prototype

**Ceilings:** this file ≤ 160 lines. No algorithms.

## Status

- Completed: mandate authoring (this tree).
- Current: freeze gate, draft PR, dispatch OWNER.
- Blockers: none at plan time. `glm` needs `pi` on PATH; launch
  prefixes
  `/nix/store/bw8ryqrsjmb3pmxranmhf46dv5z3miyr-pi-0.84.4/bin`.
  If `glm --approve` cannot start, T.O. files Q-001 rather than
  substituting a family.

## Technical strategy

Greenfield Haskell app in this repo. One bisect-safe slice: the
whole prototype. Topology: **OWNER** (ghcNative + rspeedy bundle +
domain semantics are not a complete LIGHT gate; no approved
sandbox launcher is named; no device on this host).

Pin **miso's flake** (`github:dmjio/miso`) so
`miso.lib.<system>.ghcNative` and `miso.lib.<system>.mkLynxBundle`
are the only native-build machinery. Follow
`packages.sample-app-native-bundle` / `sample-app-native-conformance`
shape: `callCabal2nix` the app with `miso = ghcNative.miso-native`,
then `mkLynxBundle { jsDrv, exeName, styles }`. Flake
`nixConfig` extra-substituters: `haskell-miso-cachix`.

Native GHC (default `devShell`) owns tests. `ghcNative` (GHCJS
9.12.2 + `-fnative`) owns the Lynx executable. Do not run Hspec
under ghcjs.

Domain: copy `src/Giacenza/{Types,Parse,Compute}.hs` and
`test/Giacenza/{ComputeSpec,ParseSpec}.hs` from
`/code/giacenza-miso`. Forbidden deps: `cassava`, `streaming`,
`attoparsec`.

UI: one miso-native component. Paste textarea (`textarea_` from
`Miso.Native.X.Element`), header-cycle taps, European/American
toggle, compute tap, result/error nodes with stable ids. Cite
`sample-app-native/Conformance.hs` for `nativeWithContext` +
`event . static`. Do not use HTML DOM (`Miso.Html.Element`).

## Constraints

- House Haskell: fourmolu (`column-limit: 70`, leading commas/
  arrows, `haddock-style: multi-line`), `-O0` in just recipes,
  `cabal check` clean, Haddock on exports, module headers.
- `just` recipes wrap cabal/nix. `just ci` is native (unit,
  format-check, hlint, cabal-check). The **slice gate still
  requires `nix build .#giacenza-lynx-bundle`**.
- `draft=NONE`. Commit owner: `glm --approve` (`harness=pi
  provider=zai model=glm-5.3-flash effort=max`). Auditor:
  `claude --dangerously-skip-permissions --model 'claude-opus-5[1m]'`.
- T.O. is grok (parent dispatch). One grok seat: auditor is not grok.
  GLM is never an auditor.
- Commit owner commits implementation into this branch. T.O. does
  not merge. T.O. (or the owner, directed) opens the PR and leaves
  it open.
- Do not edit `/code/giacenza-miso`, `/code/giacenza-browser`,
  `/code/giacenza`, or any host outside this worktree.
- If `ghcNative` / `mkLynxBundle` fails to build at all on this
  host's nix store, file a BLOCKED question. Do not silently fall
  back to wasm, GHC, or a stub file named `.lynx.bundle`.

## Live boundary

The unit suite cannot see: ghcjs compile, rspeedy bundling, Lynx
runtime, or a physical device. Per live-boundary-smoke:

- Gate includes `nix build` of the bundle plus the inspector
  (loud fail if missing, empty, sha256 mismatch, or stub-sized).
- Device runtime is a named operator follow-up **after** COMPLETE,
  owned by the parent. This ticket does not load the bundle on a
  phone or emulator.

## Slices

| ID | Mode | Outcome |
|----|------|---------|
| S1 | OWNER | Domain + native UI + flake bundle + PR body notes |

Pre-slice base: HEAD after the planning commits on
`prototype/lynx-native-calculator`.

## Verification commands (named, not implemented here)

- Focused RED/GREEN: `nix develop --quiet -c just unit`
- Format: `nix develop --quiet -c just format-check`
- Full native: `nix develop --quiet -c just ci`
- Bundle: `nix build --quiet .#giacenza-lynx-bundle`
- Inspector: the frozen slice gate's bundle checks

## Build budget

`builds_budget=8` (auditor-spent). `ghcNative` + rspeedy compiles
are the scarce item; native `-O0` tests are free readiness.

## Residuals expected

- GitHub Actions on this PR will not run until a workflow exists
  on `main`. Out of slice: do not bootstrap org CI on `main`.
- Device run, Android host APK, iOS: out of slice.
- File upload, multi-statement, theme: out of slice.
