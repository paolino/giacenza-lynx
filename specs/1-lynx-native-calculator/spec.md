# Spec — giacenza miso-native / LynxJS prototype (issue #1)

**Input:** https://github.com/paolino/giacenza-lynx/issues/1
**Ceilings:** this file ≤ 180 lines.

## Paramount user story

A person pastes a bank-movement CSV into a native Lynx app, confirms
the date column, amount column, and number format, and sees a
per-year table of *saldo* (31 Dec balance) and *giacenza* (average
daily balance). A bad paste or bad column shows a visible error
instead of a silent wrong table. This ticket proves the
**miso-native / LynxJS bundle pipeline**, not a hosted page.

## Why this ticket exists

Third giacenza prototype (after browser Halogen and miso wasm).
Distinctive claim under test: one Haskell source, a real native
mobile artifact (`main.lynx.bundle`). The evaluation (build time,
error quality, how far verification went without a device) belongs
in the PR body. The calculator must still be correct.

Canonical domain: copy `Giacenza.Types` / `Parse` / `Compute` from
`paolino/giacenza-miso` (do not re-derive). UI shape: paste path
only of that sibling, rendered with Lynx core + X textarea. Do not
edit `giacenza-miso` or `dmjio/miso`.

## Functional requirements

- FR-001: CSV arrives only through a pasted-text area. No file
  picker, drag-drop, or multi-file list.
- FR-002: First non-empty line is the header. Fields split on
  comma or semicolon; quoted fields follow the giacenza-browser
  splitter. Header names are trimmed.
- FR-003: After paste, date-column and amount-column default to
  the first and second headers. Number format is European
  (`1.234,56`) or American (`1,234.56`); European is the default.
  Taps cycle headers / toggle format (Lynx has no HTML `<select>`).
- FR-004: Dates are `YYYY-MM-DD`. Amounts parse as production
  `parseValue`. Missing column, unparseable date, or unparseable
  amount is a visible error; the result table is not shown.
- FR-005: Movements apply in CSV row order (`foldDays`). Sparse
  movements expand to a dense daily balance; after the last
  movement, fill through 31 Dec of that movement's year. Days
  before the first movement are omitted, not zero.
- FR-006: For each year that has a 31 Dec balance, *saldo* is that
  balance and *giacenza* is (sum of emitted daily balances) /
  (365, or 366 if leap). Divisor is calendar year length, not
  emitted-day count.
- FR-007: The result lists year, giacenza, saldo. Amounts display
  with two decimal places (`showFFloat (Just 2)`).
- FR-008: Header-only CSV shows an empty result, not an error.
  Empty paste shows a visible error.
- FR-009: The app is a miso-native dual-thread component
  (`nativeWithContext`, handlers `event . static` as required).
  Native GHC tests cover FR-004–FR-008. The Lynx bundle is a
  separate flake output.
- FR-010: `nix build` produces `main.lynx.bundle` +
  `main.lynx.bundle.sha256` via `miso.lib.<system>.mkLynxBundle`
  and `miso.lib.<system>.ghcNative.callCabal2nix`.
- FR-011: The PR body records the native-build experience: wall
  time of a clean bundle build, quality of a deliberate compile
  error, what bundle inspection showed, and what could not be
  checked without a device. Do not claim it runs on a phone.

## Invariants

BLOCKING = wrong money figure, silent failure, or missing/stub
bundle. ADVISORY = eval notes.

- INV-1-CONST (BLOCKING): American CSV `date,amount` /
  `2023-01-01,100` → year 2023, saldo 100, giacenza 100.
- INV-1-EURO (BLOCKING): European amount `1.234,56` on 2023-01-01
  → saldo 1234.56, giacenza 1234.56. Negative `-1.234,56` negates.
- INV-1-AMER (BLOCKING): American amount `1,234.56` on 2023-01-01
  → saldo 1234.56, giacenza 1234.56.
- INV-1-GAP (BLOCKING): 2024 (leap) `2024-01-01,1000` then
  `2024-06-01,-200` → saldo 800, giacenza `(152*1000+214*800)/366`.
- INV-1-PARTIAL-YEAR (BLOCKING): only `2023-06-01,50` → saldo 50,
  giacenza `(214*50)/365`. Days before 1 Jun omitted.
- INV-1-YEAR-CROSS (BLOCKING): `2023-12-31,10` then `2024-01-01,5`
  → 2023 saldo 10, giacenza `10/365`; 2024 saldo 15, giacenza 15.
- INV-1-EMPTY-ROWS (BLOCKING): headers only → empty table, no error.
- INV-1-ERROR-DATE (BLOCKING): bad date or missing column name →
  visible error text; no saldo/giacenza numbers from that paste.
- INV-1-ERROR-EMPTY (BLOCKING): empty paste → visible error.
- INV-1-BUNDLE (BLOCKING): `nix build .#giacenza-lynx-bundle`
  yields a `main.lynx.bundle` + matching `main.lynx.bundle.sha256`
  that pass the gate inspector (sha256 verifies, non-stub size,
  compiled marker or ≥ 1 MiB).
- INV-1-DEVLOOP (ADVISORY): PR body contains the FR-011 notes.
- INV-1-DEVICE (ADVISORY): no physical device or emulator on this
  host; runtime on iOS/Android is an operator follow-up *after*
  this ticket's COMPLETE. Residual, not a ship blocker.

## Success criteria

- Native tests fail if any BLOCKING compute/parse invariant is
  violated, and have been shown red on a mutant of that oracle.
- The flake bundle output exists and passes the inspector.
- PR opened into `main`, left unmerged, with FR-011 notes.

## Non-goals

Copied from the issue; binding, not advisory.

- No hosting or exposing the bundle anywhere reachable. Producing
  `main.lynx.bundle` as a build artifact in the repo/PR is the
  entire deliverable. Do not stand up a server, do not SSH
  anywhere, do not touch any production host, do not touch
  `plutimus.com` or `lambdasistemi.net` or any `epyc` path.
- No Android Studio / Gradle host-app build, unless it turns out
  to be genuinely trivial and clearly still within a "small
  prototype" time budget — the flake-produced `.lynx.bundle`
  artifact alone satisfies acceptance criteria.
- Stop at COMPLETE. Once acceptance criteria are met and the PR
  is open, write COMPLETE and stop.
- No App Store / Play Store publishing.
- No iOS build (no Xcode on this host).
- No file-upload UI, multi-statement workflow, or theme toggle.
- Do not merge the PR.

## Assumptions

- Header delimiter is comma or semicolon, not tab.
- Production `parseValue` cents are `decimal / 100` (`1,5`
  European = 1.05). Match that.
- No sort step. Unsorted dates follow Haskell `foldDays`.
- Domain copy from giacenza-miso is preferred over a cabal
  source-repository-package: the sibling's package also builds a
  wasm app on a different GHC. PR notes the copy.
