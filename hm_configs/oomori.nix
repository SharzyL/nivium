{ pkgs, ... }:

{
  home.username = "sharzy";
  home.homeDirectory = "/home/sharzy";
  nivium.profile = "full";

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
