final: prev:
{
  keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICYGbacmgagiCFB/xB1tordQsYbDoT1Fge4VNK5ybYXc ssh@genesis"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDeib2S3KJRAYnSLy47UJxdI3VSt1dSZ5r4jbN/EhTEI gpg@genesis"
  ];

  # self-packaged packages overrides
  efb = prev.efb.override { python3 = final.python310; };
  logchecker = prev.logchecker.override { python3 = final.python311; };
  derper = prev.derper.override { buildGoModule = final.buildGo123Module; };

  # until qbittorrent5 is supported
  qbittorrent-nox = final.libsForQt5.callPackage ./in-overlay/qbittorrent4 {
    guiSupport = false;
    inherit (final.apple_sdk.frameworks) Cocoa;
  };

  # other self-packaged packages
  LuaMyNvim = final.callPackage ../modules/hm/LuaMyNvim { };
  python3 = prev.python3.override {
    packageOverrides = pfinal: pprev: {
      pygments-extra = pprev.pygments.overridePythonAttrs (oldAttrs: {
        propagatedBuildInputs = (oldAttrs.propagatedBuildInputs or [ ]) ++ [ final.spice-lexer ];
      });
    };
  };
}
