{ ... }:

{
  imports = [
    ./git.nix
    ./nvim.nix
    ./fish.nix
    ./fish-zoxide.nix
    ./i3.nix
    ./graphics-common.nix
    ./sway.nix
    ./niri.nix
    ./base.nix
    ./tmux.nix
    ./attic-cache.nix
    ./fcitx5-rime.nix
    ./kitty.nix
    ./yazi.nix
  ];

  gtk.enable = true;
}
