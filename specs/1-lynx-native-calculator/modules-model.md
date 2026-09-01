# Modules model — issue #1

New modules only. No bodies, imports, or algorithms.
Upstream = dependency-graph owner, not a Git remote.

## M-TYPES — `src/Giacenza/Types.hs`

Owns: `Value`, `Year`, `Saldo`, `Giacenza`, `Movement`,
`NumberFormat`, `Config`, `Result`, `ParseError`.
Depends on: none of the modules below.
Promoted: these types are the shared language. Do not fork a
second money/date vocabulary in the UI.
Source: copy from `paolino/giacenza-miso`.

## M-PARSE — `src/Giacenza/Parse.hs`

Owns: CSV text → headers + rows; header-name lookup; date field;
amount field under a `NumberFormat`.
Depends on: M-TYPES.
Does not own: daily expansion or year aggregation.
Source: copy from `paolino/giacenza-miso`.

## M-COMPUTE — `src/Giacenza/Compute.hs`

Owns: movements → per-year `(Saldo, Giacenza)` with production
`foldDays` / year-end fill / leap divisor semantics.
Depends on: M-TYPES.
Does not own: CSV or native view.
Source: copy from `paolino/giacenza-miso`.

## M-APP — `app/Main.hs`

Owns: miso-native model, actions, view, `main` via
`nativeWithContext`.
Depends on: M-TYPES, M-PARSE, M-COMPUTE, `miso` (`-fnative`).
Does not own: a second parser or a second average-balance formula.
Does not use `Miso.Html.Element` (web DOM). Native surface is
`view_` / `text_` plus X `textarea_`.

## M-TEST — `test/`

Owns: native Hspec + QuickCheck proofs of the spec invariants.
Depends on: M-TYPES, M-PARSE, M-COMPUTE.
Does not own: production modules. Does not run under ghcjs.

## M-BUILD — flake / cabal / just / styles

Owns: native `devShell`, `ghcNative` executable, `mkLynxBundle`
flake output `giacenza-lynx-bundle`, just recipes, package
metadata, optional `styles.css` compiled into the bundle as
cssId 0.
Depends on: M-APP as the ghcjs executable.
Forbidden: `cassava`, `streaming`, `attoparsec`; hosting the
bundle; Android/iOS host apps; editing the reference repositories.

## Direction

```
M-BUILD → M-APP → M-PARSE → M-TYPES
                 → M-COMPUTE → M-TYPES
M-TEST  → M-PARSE, M-COMPUTE, M-TYPES
```

No reverse edge from domain modules into M-APP.
