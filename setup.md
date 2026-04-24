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
- [xsv](https://github.com/BurntSushi/xsv)

## Configs

Symlinks:

```
ln -s ~/personal/env/alacritty/alacritty.yml ~/.config/alacritty/alacritty.yml
ln -s ~/personal/env/claude/agents ~/.claude/agents
ln -s ~/personal/env/claude/commands ~/.claude/commands
ln -s ~/personal/env/claude/keybindings.json ~/.claude/keybindings.json
ln -s ~/personal/env/claude/settings.json ~/.claude/settings.json
ln -s ~/personal/env/claude/skills ~/.claude/skills
ln -s ~/personal/env/claude/statusline.sh ~/.claude/statusline.sh
ln -s ~/personal/env/ghostty/config ~/.config/ghostty/config
ln -s ~/personal/env/git/.gitconfig ~/.gitconfig
ln -s ~/personal/env/karabiner/karabiner.json ~/.config/karabiner/karabiner.json
ln -s ~/personal/env/nvim ~/.config/nvim
ln -s ~/personal/env/tmux/.tmux.conf ~/.tmux.conf
ln -s ~/personal/env/vim/.vimrc ~/.vimrc
ln -s ~/personal/env/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
ln -s ~/personal/env/zsh/.zshrc ~/.zshrc
ln -s ~/personal/env/direnv/direnvrc ~/.config/direnv/direnvrc
ln -s ~/personal/env/direnv/direnv.toml ~/.config/direnv/direnv.toml
ln -s ~/personal/env/zsh/aaronharper.zsh-theme ~/.oh-my-zsh/custom/themes/aaronharper.zsh-theme
```

## Nix

Uses [Determinate Nix](https://github.com/DeterminateSystems/nix-installer). The installer creates `/etc/nix/nix.custom.conf` for user overrides, so we use `-sf` to replace it with our symlink:

```
sudo ln -sf ~/personal/env/nix/nix.custom.conf /etc/nix/nix.custom.conf
```

After changing the config, restart the daemon:

```
sudo launchctl kickstart -k system/systems.determinate.nix-daemon
```

## VS Code

Extensions:

- Bookmarks
- ESLint
- GitHub Copilot
- GitLens
- Go
- HashiCorp Terraform
- Isort
- Makefile Tools
- Prettier
- Python
- Vim
- YAML
