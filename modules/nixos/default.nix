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
    ./home-base.nix
    ./graphics
    ./dhack
    ./systemd-hardening.nix
  ] ++ (map (flake: flake.nixosModules.default) (with self.inputs; [
    sops-nix
    home-manager
    impermanence
    tg-searcher
    chatgpt-telegram-bot
  ])) ++ (dirFiles "services") ++ (dirFiles "programs");
}

