{ lib, ... }:

let
  options = {
    enable = true;
    delta.enable = lib.mkDefault true;
    lfs.enable = lib.mkDefault true;
    userName = "SharzyL";
    userEmail = "me@sharzy.in";
    aliases = {
      g = "log --graph --pretty=format:'%Cred%h%Creset - %s %Cgreen(%cr) %C(bold blue)%an%Creset %C(yellow)%d%Creset'";
      ga = "log --graph --all --pretty=format:'%Cred%h%Creset - %s %Cgreen(%cr) %C(bold blue)%an%Creset %C(yellow)%d%Creset'";
      s = "status --short";
      st = "diff --stat";
      d = "diff";
      bd = "-c delta.side-by-side=true diff";

      a = "add";
      c = "commit";
      t = "tag";
      m = "merge";
      l = "log";
      sm = "submodule";

      p = "push";
      pu = "pull";

      b = "branch";
      cl = "clone";
      co = "checkout";

      sw = "switch";
      rb = "rebase";
      rt = "restore";
      rs = "reset";
      rv = "revert";
    };
    extraConfig = {
      commit.gpgSign = true;
      tag.gpgSign = true;
      gpg = {
        format = "ssh";
        ssh.defaultKeyCommand = "ssh-add -L";
        ssh.allowedSignersFile = "~/.ssh/allowed_signers";
      };
      core = {
        autocrlf = false; # disable automatic crlf conversion
        quotepath = "off"; # display unicode filename
      };
      merge = {
        tool = "meld";
        conflictstyle = "diff3";
      };
      mergetool = {
        keepBackup = false;
        keepTemporaries = false;
        writeToTemp = true;
      };
      credential.helper = "cache";
      init.defaultBranch = "goshujin";
      pull.rebase = true;
      fetch.prune = true;
      merge.conflictStyle = "diff3";
    };
  };
in
{
  programs.git = options;
}
