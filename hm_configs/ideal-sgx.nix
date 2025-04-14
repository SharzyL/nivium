{ ... }:

{
  setup.profile = "minimal";

  home.username = "yunqian";
  home.homeDirectory = "/home/yunqian";
  programs.bash.enable = true;  # since bash is the login shell
}
