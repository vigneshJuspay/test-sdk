# Error codes

Error codes PeekKit can report in its status.

| Code | When | What to do | Retry as is? |
| --- | --- | --- | --- |
| `PAGE_UNAVAILABLE` | The random page could not be loaded: the site is down, or the device is offline | Try again later, or pick another moment to peek | Yes |

<!-- passthrough-error-codes
The codes below come from the web page PeekKit opens, not from PeekKit's own code.
List each one on its own line, or CI fails.
PAGE_UNAVAILABLE
-->
