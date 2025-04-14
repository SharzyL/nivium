{ ... }:

{
  home.username = "luoyunqian";
  home.homeDirectory = "/scorpio/home/luoyunqian";
  setup.profile = "full";

  programs.bash = {
    enable = true;
    # to add necessary env to non-interactive bash
    bashrcExtra = ''
      source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    '';
  };
}
