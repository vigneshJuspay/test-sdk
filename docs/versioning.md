# Versioning

PeekKit follows [Semantic Versioning](https://semver.org): `MAJOR.MINOR.PATCH`.

| Release | Example | What it can contain |
| --- | --- | --- |
| Patch | 1.0.1 → 1.0.2 | Fixes and internal changes. The public API does not change |
| Minor | 1.0.2 → 1.1.0 | New public API, plus anything a patch can contain. |
| Major | 1.1.0 → 2.0.0 | Breaking changes. Code written for the previous version may need changes; the release notes list each one under "Breaking changes" with what to change |

## What counts as a breaking change

Removing or renaming a public class, method or type alias (for example `Peeker`, `Peeker.peek` or `PeekHandler`), or changing a public method's parameters or return type.

## Deprecation

A deprecated part of the public API is removed only in a major release, and only once at least six months have passed since the release that deprecated it. Until then it stays in every release. The release notes list every deprecation, with what to use instead and the version it will be removed in.
