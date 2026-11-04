# Contributing

Keep Pipeline focused on transport, routing, and middleware composition. Features such as serialization, throttling, metrics, and logging belong outside the core.

Luau source uses strict types, path labels, role-based comments where useful, explicit receiver types, guard-first control flow, and `const` for fixed policy values. Do not use `any` to conceal type errors.

Before opening a PR:

1. Run `node tests/run.mjs` with Luau CLI installed.
2. Compile every changed Luau file with `luau-compile`.
3. Verify reliable and unreliable send/receive behavior in Roblox Studio if the transport changed.
4. Explain any new allocation or hot-path branch introduced by the change.

Do not claim performance gains without reproducible measurements.
