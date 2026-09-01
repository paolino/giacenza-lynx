# Spec — native textarea input registration (issue #3)

**Input:** https://github.com/paolino/giacenza-lynx/issues/3
**Ceiling:** 100 lines.

## Outcome

Typing or pasting into `paste-area` dispatches `CsvInputChanged` with the
textarea's current value on Lynx native. The existing model update then detects
CSV headers. Device confirmation is a parent-owned follow-up; this host proves
the registration and decoder path through source, compile/link, bundle
inspection, and the existing native suite.

## Root cause

Pinned miso `53cfebf5e200f3f866f8756ec2e9d1d982622e81` registers X input events
directly, so `nativeEvents <> nativeXEvents` is not the missing piece. The
problem is the app's use of `Miso.Native.X.Element.Textarea.Event.onInput`,
which selects miso's full `textareaDecoder`. That decoder requires optional
`detail.isComposing` to decode as `Int`, while Lynx's textarea API declares it
as `boolean`. A boolean payload therefore rejects the complete event before
`CsvInputChanged` is constructed.

The app needs only `detail.value`. It must keep the X `textarea_` (which owns
the non-bubbling direct-event binding) and register `input` with miso's
`textareaValueDecoder`, avoiding irrelevant composition/selection fields.
This is an explicit app-level compatibility workaround for a named upstream
miso/Lynx payload-shape gap, not a widget refactor.

## Requirements

- FR-301: `pasteArea` remains `Miso.Native.X.Element.textarea_`; do not replace
  it with an HTML or different native input widget.
- FR-302: its `input` handler decodes only `detail.value` and constructs
  `CsvInputChanged` from that value.
- FR-303: `main` continues registering `nativeEvents <> nativeXEvents`.
- FR-304: tap controls and all compute/domain behavior remain unchanged.
- FR-305: the Lynx bundle contains the app node plus miso's direct-event
  transport, and the existing native suite remains green.
- FR-306: the PR plainly names the upstream full-decoder mismatch and the
  remaining real-device confirmation.

## Invariants

- INV-3-DIRECT (ADVISORY): the X textarea constructor declares `input` as a
  direct element event; the linked bundle contains the direct-event transport.
- INV-3-VALUE (ADVISORY): the app's input handler depends only on
  `detail.value`; a documented boolean `isComposing` cannot prevent action
  construction.
- INV-3-SCOPE (ADVISORY): the implementation candidate changes only
  `app/Main.hs`; task stamping changes only this ticket's `tasks.md`.
- INV-3-REGRESSION (ADVISORY): native CI and the Lynx bundle build remain
  green, with a matching bundle checksum and non-stub size.
- INV-3-DEVICE (ADVISORY): this host has no device/emulator. On-device typing
  and paste remain a named parent follow-up, not a claim made by this PR.

## Non-goals

- No tap-control, model-update, parser, compute, style, dependency, flake, or
  upstream miso changes.
- No SSH, hosting, production path, device/emulator, APK, or merge.

