{ tailscale, buildGoModule }:

buildGoModule rec {
  pname = "derper";
  inherit (tailscale) version src vendorHash;

  env.CGO_ENABLED = 0;

  subPackages = [ "cmd/derper" ];

  ldflags = [ "-X tailscale.com/version.Long=${version}" "-X tailscale.com/version.Short=${version}" ];

  doCheck = false; # requires networking

  inherit (tailscale) meta;
}

