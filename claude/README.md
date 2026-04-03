# Claude Code settings

## `enableWeakerNetworkIsolation`

Enabled to make the `gh` CLI work. Without it, there were cert errors in Claude's sandbox. Go binaries need access to macOS's `trustd` service to verify TLS certificates through the sandbox proxy.

## `sandbox.filesystem.allowWrite`

- `~/Library/Caches/go-build` - Fixes `go build` issues in sandbox
- `~/.cache/uv` - Fixes `uv` issues in sandbox

## `env.UV_NO_SYNC`

Fixes Nix-installed `uv` panicking in the sandbox. The Nix-built binary calls `SCDynamicStoreCopyProxies` (macOS system proxy API), which the sandbox blocks. Setting `UV_NO_SYNC=1` makes `uv run` skip the sync step entirely, avoiding the proxy call. The tradeoff is that `uv sync` must be run manually outside the sandbox after adding new dependencies.
