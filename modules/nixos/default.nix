let
  dirFiles = path: (builtins.attrValues
    (builtins.mapAttrs
      (name: _: ./${path}/${name})
      (builtins.readDir (./. + "/${path}"))
    )
  );
in
{ self, ... }:
{
  imports = [
    ./base.nix
    ./nivium.nix
    ./home-base.nix
    ./graphics
    ./systemd-hardening.nix
    ./u2f-skip-remote.nix
  ] ++ (map (flake: flake.nixosModules.default) (with self.inputs; [
    sops-nix
    home-manager
    impermanence

    tg-searcher
    chatgpt-telegram-bot
  ])) ++ (dirFiles "services") ++ (dirFiles "programs");
}

