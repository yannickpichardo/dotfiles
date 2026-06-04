# Neovim Dotfiles Layout

This config is split into shared core modules and optional language modules so it can be reused across different machines.

## Structure

- `lua/plugins/core/`: shared editor and tooling config
- `lua/plugins/lang/`: language-specific plugins and LSP config
- `lua/config/features.lua`: feature toggles for optional language stacks

## Machine Toggles

You can disable language stacks with environment variables:

```bash
export NVIM_ENABLE_PYTHON=0
export NVIM_ENABLE_SWIFT=0
```

Defaults:

- Python: enabled
- Swift: enabled

## Local Machine Overrides

For per-machine settings that should not live in shared dotfiles, create:

```lua
-- lua/config/local.lua
return {
  lang = {
    python = true,
    swift = false,
  },
}
```

`config.local` is optional and overrides `config.features`.

## Swift/Xcode Projects

If Swift is enabled and `xcode-build-server` is installed, generate a `buildServer.json` for the current Xcode project with:

```vim
:XcodeBuildServerConfig
```

Or specify a scheme:

```vim
:XcodeBuildServerConfig MyScheme
```
