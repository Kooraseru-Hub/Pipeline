# Changelog

## Unreleased: middleware-first redesign

- Replaced the previous staged framework with one small, explicit networking runtime.
- Added one reliable and one unreliable transport, each routing numeric channels.
- Added global and per-channel send/receive middleware, composed on registration.
- Added a no-middleware fast path without packet tables or custom serialization.
- Removed the old serialization, batching, logging, tracing, metrics, registry, rate limiting, validation, and RPC implementations.
- Added explicit transport ownership and teardown.
- **Breaking:** the old `Init`, `GetEvent`, and `GetFunction` APIs are removed.

This is an intentional rewrite, not a backwards-compatible release.
