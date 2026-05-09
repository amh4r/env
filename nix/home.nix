{ pkgs, ... }:

{
  home.username = "aaron";
  home.homeDirectory = "/Users/aaron";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    direnv
    fx
    fzf
    gping
    htop
    jq
    ngrok
    nix-direnv
    pyenv
    ripgrep
    tmux
    uv
  ];

  programs.home-manager.enable = true;
}
