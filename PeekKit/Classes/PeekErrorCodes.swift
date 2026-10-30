// Error codes PeekKit sends; send them as PeekErrorCodes.X, never as strings.
// When you add a code here, add a row for it to the table in docs/error-codes.md: when it is
// sent, what the app should do, and whether trying again as is can work.
// CI (scripts/verify-error-codes.sh) fails if a code here has no row in that table.
enum PeekErrorCodes {}
