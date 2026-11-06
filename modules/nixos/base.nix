{ config, pkgs, lib, ... }:

# what every nivium host gets; the toggles live in ./nivium.nix

with lib;
let
  cfg = config.nivium;
in
{
  sops = {
    defaultSopsFile = ../../secrets/general.yaml;
    age = {
      keyFile = lib.mkDefault "/var/lib/nivium/sops.key";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];

    secrets."user_passwd" = { neededForUsers = true; };
  };

  systemd.tmpfiles.rules = [ "d /var/lib/nivium 0755 root root - -" ];

  security.sudo.extraConfig = ''
    Defaults lecture="never"
  '';

  nix = {
    package = pkgs.nixVersions.latest;
    channel.enable = false;
    settings = {
      trusted-users = mkBefore [ "root" cfg.adminUser ];
      experimental-features = mkBefore [ "nix-command" "flakes" "auto-allocate-uids" "cgroups" "ca-derivations" ];
      use-xdg-base-directories = true;
      auto-optimise-store = mkDefault true;
      builders-use-substitutes = false;
      use-cgroups = true;
    };
  };

  time.timeZone = mkDefault "Asia/Shanghai";

  users.defaultUserShell = pkgs.fish;
  programs = {
    fish = {
      enable = true;
      useBabelfish = true;
    };

    neovim = {
      enable = true;
      defaultEditor = true;
    };

    gnupg.agent = {
      enable = true;
      enableSSHSupport = mkDefault true;
    };
  };

  users.mutableUsers = false;
  users.users = {
    root = {
      openssh.authorizedKeys.keys = pkgs.keys;
      hashedPasswordFile = config.sops.secrets."user_passwd".path;
    };

    sharzy = {
      uid = mkDefault 1000;
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      hashedPasswordFile = config.sops.secrets."user_passwd".path;
      openssh.authorizedKeys.keys = pkgs.keys;
    };
  };

  environment.etc."ssh/trusted_user_ca_keys".text = ''
    ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBIa1ySKa6MhJmDYECMefviL6eWB/vuJzH51i8LR/9T76Ezrwc/PnNOhHyJAH7zAgEX95QN8M8VuD5Xbs1ugqyuU= sharzy-akiko-ca
  '';

  services.openssh = {
    enable = mkDefault true;
    listenAddresses = mkBefore [
      { addr = "[::]"; port = 22; }
      { addr = "0.0.0.0"; port = 22; }
    ];
    settings.PasswordAuthentication = mkDefault false;
    settings.TrustedUserCAKeys = "/etc/ssh/trusted_user_ca_keys";
    extraConfig = mkAfter ''
      StreamLocalBindUnlink yes
      LoginGraceTime 0
    '';
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
  };

  networking = {
    firewall.enable = mkDefault false;
    hostName = cfg.hostName;
  };
}
