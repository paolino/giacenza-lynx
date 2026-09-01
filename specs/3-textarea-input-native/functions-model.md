# Functions model — issue #3

**Ceiling:** 35 lines. Changed signature-level contracts only.

## M3-APP

- `pasteArea :: value -> View context Model Action`

`value` remains the current model value. The textarea's `input` attribute must
decode only the event's current string value and convert it to
`CsvInputChanged`.

- `main :: IO ()`

The event map remains the union of native built-in and X-element maps.

No new model action, update function, helper API, or exported production
function is authorized.

