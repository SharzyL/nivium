{ pkgs, ... }:

{
  home.username = "sharzy";
  home.homeDirectory = "/home/sharzy";
  setup.profile = "full";

  home.packages = with pkgs; [
    torrenttools
    ranger
    sharzyscripts
    music-tag
    cuetools
    shntool
    imagemagick
  ];
}
