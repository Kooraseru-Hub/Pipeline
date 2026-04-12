# Contributing to Pipeline

Thank you for your interest in contributing to Pipeline! This document provides guidelines and instructions for contributing to the project.

---

## Getting Started

### Prerequisites

- **Luau/Roblox Studio** for testing changes
- **Git** for version control
- Basic understanding of the Pipeline system (see [README.md](README.md))

### Setting Up the Development Environment

1. **Fork the Repository**
   ```bash
   # Visit https://github.com/Kooraseru-Hub/Pipeline and click "Fork"
   ```

2. **Clone Your Fork**
   ```bash
   git clone https://github.com/Kooraseru-Hub/Pipeline.git
   cd Pipeline
   ```

3. **Create a Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or for bug fixes:
   git checkout -b bugfix/issue-description
   ```

---

## Development Workflow

### Code Style

Pipeline enforces consistent code style via the `.rules/` directory conventions:

1. **Follow Luau Style Rules** (`.rules/luau/`)
   - **Naming**: PascalCase for module functions, SCREAMING_SNAKE_CASE for constants, camelCase for local variables and helpers
   - **Functions**: Use method syntax (`:`) by default for module functions, include type annotations on all parameters and returns
   - **Comments**: Include the file path label as the first line, directives (`--!strict`, `--!optimize 2`), and documentation blocks for public functions

2. **Example Stage Handler Structure**
   ```lua
   -- Shared/Pipeline/Stages/PostSend/MyHandler.luau
   --!strict
   --!optimize 2

   local MyHandler = {}
   MyHandler.type = "MyHandler"

   --[[
       Handles the message in the PostSend stage.
       @param network Network The active network instance.
       @param message Message The pipeline message.
   ]]
   function MyHandler:Handle(network: any, message: any)
       -- Implementation
   end

   return MyHandler
   ```

3. **Key Points**
   - Always include `-- path/to/file.luau` as the first line
   - Use `--!strict` and `--!optimize 2` directives
   - Document public functions with `--[[ ... ]]` block comments using `@param` and `@return`
   - Prefer `:` over `.` for method definitions on module tables

### Testing

Before submitting a pull request:

> [!IMPORTANT]
> Test all changes in Roblox Studio. Verify that messages flow through the full pipeline (PreSend, Validation, Sending, PostSend) and that dropped messages still reach PostSend. Test the Relay path separately, as it bypasses the Validation stage.

1. **Manual Testing**
   - Test your changes in Roblox Studio with a live client-server session
   - Verify that `GetEvent` and `GetFunction` objects fire and invoke correctly
   - Test lifecycle: Init, fire from client, receive on server, fire back to client
   - Run error scenarios and edge cases (dropped messages, rate limit exceeded)

2. **Config Flag Testing**
   ```lua
   -- Verify disabled subsystems produce no errors
   local Config = require(game.ReplicatedStorage.Pipeline.Core.Config)
   Config.SerializerEnabled = false
   Config.TracerEnabled = false
   Config.LoggerEnabled = false
   Pipeline:Init(nil, "Pipeline")

   -- All fires should still work; just no encoding, tracing, or logging
   ```

3. **Relay Path Testing**
   - Confirm Relay messages fire `OnClientEvent` without passing through Validation
   - Confirm rate limiter and NetworkedObjects still run for Relay (PreSend stage applies)

4. **Verify No Regressions**
   - Ensure your changes do not break existing stage handlers
   - Test `Metrics:Snapshot()` counts increment correctly after fires
   - Test `Tracer:Drain()` returns spans and clears the buffer

---

## Submitting Changes

### Commit Messages

Follow conventional commit format:

```
type(scope): brief description

Optional body explaining the why and what.

Fixes #issue-number
```

**Types:**
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes (formatting, etc.)
- `refactor:` Code refactoring without feature change
- `test:` Adding or updating tests
- `chore:` Maintenance tasks

**Examples:**
```
feat(validation): add custom predicate short-circuit on first rejection
fix(bulksender): prevent heartbeat connection leak on re-initialization
docs(readme): add custom type registration example
refactor(transport): simplify server-client remote handshake
```

### Pull Request Process

1. **Before Creating PR**
   - Ensure all changes follow code style rules from `.rules/`
   - Test thoroughly in Roblox Studio, including relay and Config flag scenarios
   - Update documentation if adding or changing public API
   - Run through the checklist below

2. **Create a Pull Request**
   - Use a clear, descriptive title
   - Reference related issues (`Fixes #123`, `Related to #456`)
   - Provide a summary of changes
   - Describe how to test the changes

3. **PR Checklist**
   - [ ] Code follows `.rules/` conventions
   - [ ] Pipeline stages tested end-to-end (PreSend, Validation, Sending, PostSend)
   - [ ] Relay path tested separately (bypasses Validation stage)
   - [ ] Config flags tested: disabled subsystems produce no errors
   - [ ] No console errors or warnings introduced
   - [ ] Documentation updated if adding or changing public API
   - [ ] Examples included for new features
   - [ ] Commit messages follow conventional format

4. **Code Review**

> [!NOTE]
> Address review feedback promptly. Discuss concerns respectfully and request clarification if review comments are unclear. Changes may be requested before merging.

---

## Types of Contributions

### Bug Reports

> [!TIP]
> Search existing issues at [Kooraseru-Hub/Pipeline](https://github.com/Kooraseru-Hub/Pipeline/issues) before filing a new report. Add to an existing issue if yours is already covered.

Found an issue? Please follow these guidelines:

1. **Search Existing Issues**
   - Check if your issue has already been reported
   - Add to existing issues if applicable

2. **Report Template**
   ```
   **Describe the bug:**
   Clear, concise description of what's happening

   **Environment:**
   - Roblox Studio version:
   - Pipeline version:

   **Steps to reproduce:**
   1. Create an event via GetEvent(...)
   2. Fire from client...
   3. Error occurs...

   **Expected behavior:**
   What should happen

   **Actual behavior:**
   What actually happens

   **Code sample:**
   -- Your minimal code example
   ```

### Feature Requests

Have an idea to improve Pipeline? Help us understand:

1. **Description**
   - What problem does this solve?
   - Why is it needed?
   - How would you use it?

2. **Proposed Solution**
   - Code example or API design
   - How it fits with the existing stage system
   - Potential impact on performance or compatibility

3. **Alternatives Considered**
   - Other approaches you've thought about
   - Why your solution is better

### Documentation Improvements

> [!NOTE]
> Documentation updates are valuable contributions. Even small fixes like typos or clearer examples make a real difference.

You can:

- Fix typos and clarify existing explanations
- Add examples and use cases
- Improve code snippet formatting
- Update API docs to match implementation

---

## Code Review Guidelines

### For Contributors

- **Be open to feedback**: Reviews aim to improve code quality
- **Ask questions**: If review comments are unclear, ask
- **Suggest alternatives**: If you disagree, propose solutions
- **Keep discussions professional**: Focus on code, not people

### For Reviewers

- **Be constructive**: Suggest improvements, not just problems
- **Explain the why**: Help contributors understand reasoning
- **Acknowledge effort**: Thank contributors for their work
- **Be timely**: Review and respond within a reasonable timeframe

---

## Project Structure

```
Pipeline/
├── .rules/                  -- Style and convention rules
│   ├── luau/                -- Naming, comment, and function rules
│   └── markdown/            -- Markdown formatting rules
├── .github/                 -- GitHub integration
│   ├── ISSUE_TEMPLATE/
│   └── PULL_REQUEST_TEMPLATE/
├── src/
│   └── Pipeline/            -- Main module
│       ├── init.luau        -- Entry point, Network type, pipeline builder
│       ├── Core/            -- Config, Serializer, StateManager
│       ├── Stages/          -- PreSend, Validation, Sending, PostSend
│       └── Utilities/       -- UUID, Promise
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
└── LICENSE
```

---

## Common Tasks

### Adding a New Stage Handler

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-handler
   ```

2. **Create a `.luau` file** in the appropriate `Stages/` subdirectory (e.g., `Stages/PostSend/MyHandler.luau`).

3. **Set a unique `type` string** on the module table. This is used by `findModule` in `init.luau` to resolve the handler by tag.
   ```lua
   local MyHandler = {}
   MyHandler.type = "MyHandler"
   ```

4. **Implement `Handle(network, message)`** following the stage handler pattern.

5. **Add the module to the `modules` list** in `Stages/init.luau` under the correct stage entry. If the handler needs initialization (e.g., a `Reset` method), call it from `Pipeline:Init` using `findModule`.

6. **Update docs and CHANGELOG.md** under `[Unreleased]`.

### Fixing a Bug

1. **Create a minimal reproduction** that triggers the bug
2. **Create a bugfix branch**
   ```bash
   git checkout -b bugfix/issue-name
   ```
3. **Implement the fix** with minimal changes to unrelated code
4. **Verify the reproduction no longer triggers** and no regressions appear
5. **Update CHANGELOG.md** under `[Unreleased]`

### Adding a Custom Type

1. **Create a file** in `Stages/Validation/Types/` (e.g., `MyType.luau`).

2. **Implement the `TypeModule` interface:**
   ```lua
   local MyType = {}
   MyType.Name = "MyType"
   MyType.Tag = 20 -- unique integer, must not be 1-14 (reserved for built-ins)

   function MyType.Check(value)
       return typeof(value) == "..." -- your guard
   end

   function MyType.Encode(buf, cursor, value)
       -- write to buf, return next cursor
       return cursor
   end

   function MyType.Decode(buf, cursor)
       -- read from buf, return value and next cursor
       return nil, cursor
   end

   return MyType
   ```

3. **Register the type** either by adding it to `BUILT_IN_TYPES` in `Validator.luau` (for types bundled with Pipeline) or by documenting it as a user-registered type via `Validator:Register()`.

---

## Getting Help

> [!TIP]
> Start with [README.md](README.md) and existing issues for most questions. If still unclear, comment on a relevant GitHub issue or open a new one with reproduction steps.

---

## Recognition

All contributors are recognized in the community. Major contributions may be acknowledged in project documentation and release notes.

Thank you for contributing to Pipeline. Your efforts help make this project better for everyone.

---

## Additional Resources

- [Keep a Changelog](https://keepachangelog.com/): Changelog format reference
- [Conventional Commits](https://www.conventionalcommits.org/): Commit message standard
- [Contributor Covenant](https://www.contributor-covenant.org/): Code of Conduct basis
- [Semantic Versioning](https://semver.org/): Versioning standard used by Pipeline
