{ config, pkgs, lib, inputs, self, ... }:

let
  profile = config.nivium.profile;
in
{
  options.nivium = {
    profile = with lib; mkOption {
      # bare: has fish
      # minimal: has nvim
      # full: has nvim and lsp and some extra tools
      type = types.enum [ "full" "minimal" "bare" ];
      default = "full";
    };
    bashProfileExecFish = with lib; mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = lib.mkMerge [{
    programs.home-manager.enable = true;

    home.stateVersion = "26.05";

    home.file.".bash_profile" = lib.mkIf config.nivium.bashProfileExecFish {
      text = ''
        if [[ $- == *i* ]] && which fish >/dev/null; then
          exec fish
        fi
      '';
    };

    # ssh shells does not get systemd variables, force it here
    programs.fish.shellInit = lib.mkIf pkgs.stdenv.hostPlatform.isLinux ''
      if ! set -q __SYSTEMD_SESS_VARS_SOURCED
        set vars (${pkgs.systemd}/lib/systemd/user-environment-generators/30-systemd-environment-d-generator)
        for line in (string split '\n' "$vars" --no-empty || true)
          export "$line"
        end
      end
    '';

    home.sessionVariables = {
      __SYSTEMD_SESS_VARS_SOURCED = "1";

      # cache
      __GL_SHADER_DISK_CACHE_PATH = "${config.xdg.cacheHome}/nv";
      CUDA_CACHE_PATH = "${config.xdg.cacheHome}/nv";
      XCOMPOSECACHE = "${config.xdg.cacheHome}/X11/xcompose";

      # state
      HISTFILE = "${config.xdg.stateHome}/bash_history";
      LESSHISTFILE = "${config.xdg.stateHome}/lesshst";
      IPYTHONDIR = "${config.xdg.stateHome}/ipython";
      NODE_REPL_HISTORY = "${config.xdg.stateHome}/node_repl_history";

      # data
      CARGO_HOME = "${config.xdg.dataHome}/cargo";
      GOPATH = "${config.xdg.dataHome}/go";
      WINEPREFIX = "${config.xdg.dataHome}/wine_root";
      RUSTUP_HOME = "${config.xdg.dataHome}/rustup";
      TEXMFHOME = "${config.xdg.dataHome}/texmf";
      ANDROID_HOME = "${config.xdg.dataHome}/android";
      KERAS_HOME = "${config.xdg.dataHome}/keras";

      # shit
      PYTHONSTARTUP = (
        pkgs.writeText "start.py" ''
          import readline
          readline.write_history_file = lambda *args: None
        ''
      ).outPath;
    };

    nix = {
      package = lib.mkDefault pkgs.nixVersions.latest; # to ensure that it is using the same nix as installer
      settings = with lib; {
        use-xdg-base-directories = true;
        extra-experimental-features = mkBefore [ "nix-command" "flakes" ];
      };
      # pins by locked tarball/github record rather than by store path: `flake =
      # inputs.x` would keep the whole input tree (nixpkgs alone is 214 MiB) in
      # the closure
      nixPath = [
        "nixpkgs=flake:nixpkgs"
        "home-manager=flake:home-manager"
      ];
      registry =
        let
          pin = name: { to = self.lib.registryPin name; };
        in
        {
          nixpkgs = pin "nixpkgs";
          p = pin "nixpkgs";
          home-manager = pin "home-manager";
          hm = pin "home-manager";
          treefmt-nix = pin "treefmt-nix";
          flake-parts = pin "flake-parts";
          f.flake = self;
        };
    };

    programs.gpg = {
      enable = true;
      homedir = "${config.xdg.dataHome}/gnupg";
    };

    services.gpg-agent = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      enable = true;
      enableSshSupport = lib.mkDefault true;
      defaultCacheTtl = 10;
      enableExtraSocket = true;
      sshKeys = [
        # gpg key ed25519
        "F90805DBD1F501D34D8D3FC99940208DFD644154"
      ];
    };

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      # otherwise it links against pkgs.nix, a second nix beside config.nix.package
      nix-direnv.package = pkgs.nix-direnv.override { nix = config.nix.package; };
    };

    xdg.enable = true;

    # `curl example.com` goes over https; curl >= 7.73 reads $XDG_CONFIG_HOME/curlrc
    xdg.configFile."curlrc".text = ''
      proto-default = "https"
    '';

    home.packages = with pkgs; [
      # classical
      tmux
      git
      gnupg
      coreutils
      gnused
      gnugrep

      # networking
      curl
      wget
      mtr

      # filesystem
      tree
      file
      lsof
      unar
      p7zip
      rsync

      # some "modern" alternatives
      duf
      ncdu
      eza
      htop
      fzf
      jq
      fd
      ripgrep
      bat
      delta
    ];
  }
    (lib.mkIf (profile == "full") {
      home.packages = with pkgs; [
        nh
        cmake
        ninja
        gnumake
        trash-cli
        just
        sharzyscripts.sysutils
        iets
        nix-output-monitor
      ];
      programs.yazi.enable = true;
    })];
}
