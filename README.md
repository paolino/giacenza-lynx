# giacenza-lynx
Giacenza average-balance calculator prototype in miso-native, targeting LynxJS (real iOS/Android via miso's dual-thread native architecture) — evaluating miso's native-mobile story.

## Build & verify

Native invariant proofs (GHC 9.12.2 dev shell):

```sh
nix develop --quiet -c just unit
```

Full local CI (build, unit, format-check, hlint, cabal-check):

```sh
nix develop --quiet -c just ci
```

Lynx bundle (`main.lynx.bundle` + `main.lynx.bundle.sha256`), built with
miso's `ghcNative` package set (GHCJS + `-fnative` miso) and
`mkLynxBundle` (bun + rspeedy):

```sh
nix build .#giacenza-lynx-bundle -o result-bundle
# or: just bundle
```

The bundle is a build artifact only — nothing in this repository serves,
uploads, or deploys it anywhere.

## Layout

- `src/Giacenza/` — domain core (`Types`, `Parse`, `Compute`), copied from
  `paolino/giacenza-miso` (parseValue cents = c/100, foldDays year-end
  fill, leap-aware giacenza divisor).
- `app/Main.hs` — miso-native dual-thread UI (`nativeWithContext`, X
  `textarea_` paste path, tap-cycling column selectors, European/American
  format toggle).
- `test/` — native Hspec + QuickCheck proofs of the issue #1 invariants
  (`prop_inv1_*`).
- `specs/1-lynx-native-calculator/` — frozen mandate (spec, plan, models,
  tasks).
