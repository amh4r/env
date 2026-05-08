# My environment

## Apps

- [DataGrip](https://www.jetbrains.com/datagrip)
- [Docker Desktop](https://www.docker.com/products/docker-desktop)
- [Ghostty](https://ghostty.org)
- [Karabiner-Elements](https://karabiner-elements.pqrs.org)
- [Magnet](https://magnet.crowdcafe.com)
- [Raycast](https://www.raycast.com)
- [YubiKey Agent](https://github.com/FiloSottile/yubikey-agent)
- [YubiKey Manager](https://www.yubico.com/support/download/yubikey-manager)

## Terminal

- [Displayplacer](https://github.com/jakehilborn/displayplacer)
- [fx](https://github.com/antonmedv/fx)
- [jq](https://github.com/stedolan/jq)
- [fzf](https://github.com/junegunn/fzf)
- [gping](https://github.com/orf/gping)
- [Homebrew](https://brew.sh)
- [htop](https://github.com/htop-dev/htop)
- [Ngrok](https://ngrok.com)
- [nvm](https://github.com/nvm-sh/nvm)
- [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh)
- [Pyenv](https://github.com/pyenv/pyenv)
- [Ripgrep](https://github.com/BurntSushi/ripgrep)
- [Terraform](https://www.terraform.io)
- [tmux](https://github.com/tmux/tmux)
- [tpm](https://github.com/tmux-plugins/tpm)
- [uv](https://docs.astral.sh/uv/getting-started/installation/)
- [xsv](https://github.com/BurntSushi/xsv)

## Install

**Homebrew stuff**

```sh
brew install direnv fx fzf gping htop jq ngrok pyenv ripgrep uv yubikey-agent
brew install --cask karabiner-elements
```

**SSH and clone this repo**

```sh
brew services start yubikey-agent
export SSH_AUTH_SOCK="$(brew --prefix)/var/run/yubikey-agent.sock"
git clone git@github.com:amh4r/env.git ~/personal/env
```

**Fzf**

```sh
$(brew --prefix)/opt/fzf/install
```

**Nix**

Uses [Determinate Nix](https://github.com/DeterminateSystems/nix-installer). The installer creates `/etc/nix/nix.custom.conf` for user overrides, so we use `-sf` to replace it with our symlink:

```sh
sudo ln -sf ~/personal/env/nix/nix.custom.conf /etc/nix/nix.custom.conf
```

After changing the config, restart the daemon:

```sh
sudo launchctl kickstart -k system/systems.determinate.nix-daemon
```

Setup direnv:

```sh
nix profile install nixpkgs#nix-direnv
```

**Oh My Zsh**

```sh
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

**Tmux**

```sh
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

**VS Code**

Cmd+Shift+P → "Shell Command: Install 'code' command in PATH"

## Configs

Symlinks:

```
ln -sn ~/personal/env/claude/agents ~/.claude/agents
ln -sn ~/personal/env/claude/commands ~/.claude/commands
ln -sn ~/personal/env/claude/keybindings.json ~/.claude/keybindings.json
ln -sn ~/personal/env/claude/settings.json ~/.claude/settings.json
ln -sn ~/personal/env/claude/skills ~/.claude/skills
ln -sn ~/personal/env/claude/statusline.sh ~/.claude/statusline.sh
ln -sn ~/personal/env/ghostty/config ~/.config/ghostty/config
ln -sn ~/personal/env/git/.gitconfig ~/.gitconfig
ln -sn ~/personal/env/karabiner/karabiner.json ~/.config/karabiner/karabiner.json
ln -sn ~/personal/env/nvim ~/.config/nvim
ln -sn ~/personal/env/tmux/.tmux.conf ~/.tmux.conf
ln -sn ~/personal/env/vim/.vimrc ~/.vimrc
ln -sn ~/personal/env/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
ln -sn ~/personal/env/zsh/.zshrc ~/.zshrc
ln -sn ~/personal/env/direnv/direnvrc ~/.config/direnv/direnvrc
ln -sn ~/personal/env/direnv/direnv.toml ~/.config/direnv/direnv.toml
ln -sn ~/personal/env/zsh/aaronharper.zsh-theme ~/.oh-my-zsh/custom/themes/aaronharper.zsh-theme
```

## VS Code

Auto-updates are disabled in `settings.json` to mitigate supply-chain attacks. Extensions are pinned to specific versions in `vscode/extensions.txt`.

Install pinned extensions:

```sh
xargs -n1 code --install-extension < ~/personal/env/vscode/extensions.txt
```

To update an extension, bump the version in `extensions.txt` and re-run the install command. Refresh the list with current versions:

```sh
code --list-extensions --show-versions > ~/personal/env/vscode/extensions.txt
```
