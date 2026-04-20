# Claude Code settings

## `enableWeakerNetworkIsolation`

Enabled to make the `gh` CLI work. Without it, there were cert errors in Claude's sandbox. Go binaries need access to macOS's `trustd` service to verify TLS certificates through the sandbox proxy.

## `sandbox.filesystem.allowWrite`

- `~/Library/Caches/go-build` - Fixes `go build` issues in sandbox
- `~/.cache/uv` - Fixes `uv` issues in sandbox
- `~/.npm` - Fixes npm/pnpm cache writes (`~/.npm/_cacache`) in sandbox

## `env.UV_NO_SYNC`

Fixes Nix-installed `uv` panicking in the sandbox. The Nix-built binary calls `SCDynamicStoreCopyProxies` (macOS system proxy API), which the sandbox blocks. Setting `UV_NO_SYNC=1` makes `uv run` skip the sync step entirely, avoiding the proxy call. The tradeoff is that `uv sync` must be run manually outside the sandbox after adding new dependencies.

## `permissions.deny`

Borrowed from [trailofbits/claude-code-config](https://github.com/trailofbits/claude-code-config/blob/main/settings.json). The sandbox restricts writes but does not restrict reads, so `Read(...)` denies plug a real gap: they stop Claude from reading SSH keys, cloud credentials (`~/.aws`, `~/.azure`, `~/.config/gh`), `~/.pypirc`, the macOS Keychain, and common crypto wallet data directories. `Edit(...)` denies block writes to shell rc files and `~/.ssh`. `Bash(...)` denies are defense-in-depth against destructive patterns (`rm -rf`, `sudo`, `mkfs`, `dd`, `wget | bash`, `git push --force`, `git reset --hard`) that would otherwise rely on the sandbox alone.

Note: `Read(...)` denies merge into the sandbox's `denyRead` filesystem list, which blocks reads at the OS level for any process spawned inside the sandbox, not just Claude's `Read` tool. That is why `~/.npmrc` and `~/.npm/**` were dropped from the deny list: pnpm and npm need to read them to resolve registries, and blocking them breaks installs and scripts. The same caveat applies to other CLIs (docker, kubectl, gh, pip). Watch for `EPERM: operation not permitted` on these paths and drop the corresponding deny rule if a tool you use needs to read them.

## `env.DISABLE_TELEMETRY`, `env.DISABLE_ERROR_REPORTING`, `env.CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY`

Turn off Anthropic usage telemetry, automated error reports, and the in-app quality survey prompt.
