{ pkgs, lib, srcs }:

pkgs.buildGoModule {
  inherit (srcs.goauthing) pname version src;

  vendorHash = "sha256-FRLpeOYOTSnq66qjljfomdSSHZhIxA0n3EcIqcoxn4c=";
  subPackages = [ "cli" ];

  postInstall = ''
    mv $out/bin/cli $out/bin/auth-thu
  '';

  meta = {
    homepage = "https://github.com/z4yx/GoAuthing";
    license = lib.licenses.gpl3Only;
  };
}
