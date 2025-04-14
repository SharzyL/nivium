{ lib
, buildGoModule
, srcs
}:

buildGoModule {
  inherit (srcs.rait) pname version src;

  vendorHash = "sha256-T/ufC4mEXRBKgsmIk8jSCQva5Td0rnFHx3UIVV+t08k=";

  subPackages = [ "cmd/rait" ];

  meta = with lib; {
    description = "Redundant Array of Inexpensive Tunnels";
    homepage = "https://gitlab.com/NickCao/RAIT";
    license = licenses.asl20;
  };
}
