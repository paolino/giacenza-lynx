# Plan — native textarea input registration

**Ceiling:** 90 lines. No implementation bodies.

## Strategy

One OWNER slice changes the textarea event attribute in `app/Main.hs`. The
X constructor remains responsible for Lynx's non-bubbling direct binding; the
handler selects the smallest upstream decoder that matches this app's data
need. No dependency pin or widget changes.

The frozen gate binds the planning base and checks both halves of the seam:

1. pinned miso's `textarea_` declares `input` in its direct-event capability;
2. the app selects `textareaValueDecoder` for `input` rather than the full
   `TaE.onInput` decoder;
3. native CI and `nix build .#giacenza-lynx-bundle` succeed;
4. the artifact has a valid checksum, non-stub size, `paste-area`, and direct
   event transport markers.

The gate is falsified against the current `TaE.onInput` wiring before
dispatch. It also carries a negative control that removes the value-only
decoder selection and requires its own wiring assertion to fail.

## Source evidence

- Pinned miso source: `Miso.Native.X.Element.textarea_` uses
  `lynxDirect_ inputDirectEvents`; that set includes `input`.
- Pinned miso source: `textareaValueDecoder` reads only `detail.value`, while
  `textareaDecoder` parses `isComposing` as `Int`.
- Lynx textarea API: `TextAreaInputEvent.isComposing` is optional `boolean`.
- No matching textarea/native report was found in dmjio/miso issues; its sample
  app uses the same full `TaE.onInput` path and therefore does not eliminate
  this mismatch.

## Slice

| ID | Mode | Tasks | Outcome |
|---|---|---|---|
| S3 | OWNER | T301 | value-only X textarea input registration |

Commit owner: GLM via `glm --approve`, exact probationary identity required.
Auditor: fresh Claude Opus 5 `[1m]`, max effort, never GLM/Codex. `draft=NONE`.

## Verification

- Frozen slice/ticket gate: runtime-root `gates/s3-textarea-input.sh`
- Native suite: `nix develop --quiet -c just ci`
- Bundle: `nix build --quiet .#giacenza-lynx-bundle`
- Bundle inspector: checksum, size, and compiled direct-event markers

`builds_budget=4`; auditor-spent bundle builds are the scarce operation.

## Residual

Real-device typing and clipboard paste are outside this host's proof surface.
The parent retests the open PR bundle after COMPLETE.

