{ ... }:

{
  sops.age.keyFile = "/persist/sops.key";
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/db"
      "/var/lib"
      # "/var/log" is already in a corresponding btrfs subvol

      "/etc/NetworkManager/system-connections"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"

      "/root/.ssh/config"
      "/root/.ssh/known_hosts"
    ];
  };
}
