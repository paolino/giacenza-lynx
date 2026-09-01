# Data model — issue #3

**Ceiling:** 45 lines. Changed data contract only.

## D3-LYNX-TEXTAREA-INPUT

Documented event detail fields:

- `value`: string, required; the only field consumed by this app.
- `selectionStart`: number, not consumed.
- `selectionEnd`: number, not consumed.
- `isComposing`: optional boolean, not consumed.

Validation boundary: failure or platform variation in an unconsumed field must
not suppress delivery of `value`.

## D3-ACTION

`CsvInputChanged` carries exactly the decoded current textarea value. The
existing update path remains the sole owner of `pasted`, detected headers,
column defaults, and outcome reset.

