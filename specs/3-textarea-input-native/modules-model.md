# Modules model — issue #3

**Ceiling:** 45 lines. Changed responsibility only.

## M3-APP — `app/Main.hs`

Owns the app-specific adapter from the Lynx X textarea `input` event to
`CsvInputChanged`. It depends on the X textarea constructor's direct-event
capability and on the smallest decoder that supplies the current value.

It does not own Lynx's event transport, miso's decoder implementation, the
model update, tap controls, parser, compute logic, styles, or build machinery.

## Upstream boundaries

- `Miso.Native.X.Element`: owns direct registration for `textarea_`.
- `Miso.Native.X.Element.Textarea.Event`: owns upstream payload decoders.
- `Miso.Event`: owns construction of the `input` attribute from an event name,
  decoder, and action converter.

The app may adapt at this boundary because its consumer needs only the value;
it must not fork or patch the upstream event transport.

