final: prev:
{
  keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICYGbacmgagiCFB/xB1tordQsYbDoT1Fge4VNK5ybYXc ssh@genesis"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDeib2S3KJRAYnSLy47UJxdI3VSt1dSZ5r4jbN/EhTEI gpg@genesis"
  ];

  # self-packaged packages overrides
  efb = prev.efb.override { python3 = final.python311; };
  logchecker = prev.logchecker.override { python3 = final.python311; };

  # until qbittorrent5 is supported
  qbittorrent-nox = final.libsForQt5.callPackage ./in-overlay/qbittorrent4 {
    guiSupport = false;
    inherit (final.apple_sdk.frameworks) Cocoa;
  };

  torrenttools = final.callPackage ./in-overlay/torrenttools { };

  # other self-packaged packages
  # Built against luajit because that's what neovim-unwrapped uses;
  # the install path (share/lua/5.1/...) must match neovim's lua.luaversion
  # so that wrapNeovim's extraLuaPackages env picks it up.
  LuaMyNvim = final.luajitPackages.callPackage ../modules/hm/LuaMyNvim { };
  python3 = prev.python3.override {
    packageOverrides = pfinal: pprev: {
      pygments-extra = pprev.pygments.overridePythonAttrs (oldAttrs: {
        propagatedBuildInputs = (oldAttrs.propagatedBuildInputs or [ ]) ++ [ final.spice-lexer ];
      });
    };
  };
}
