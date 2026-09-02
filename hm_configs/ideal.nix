{ pkgs, ... }:

{
  home.username = "luoyunqian";
  home.homeDirectory = "/scorpio/home/luoyunqian";
  nivium.profile = "full";

  home.packages = [ pkgs.uv ];

  programs.bash = {
    enable = true;
    # to add necessary env to non-interactive bash
    bashrcExtra = ''
      source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    '';
  };
}
