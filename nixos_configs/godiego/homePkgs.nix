{ pkgs, ... }:

{
  nivium.defaultBrowser = "firefox";

  home.packages = with pkgs; [
    # dev
    python3
    poetry
    bear
    nodejs
    qemu
    man-pages
    flamegraph
    rustup
    claude-code
    codex

    # media and doc cli
    imagemagick
    pandoc
    ffmpeg
    poppler-utils

    # extra cli
    w3m
    inotify-tools
    lm_sensors
    ccal
    rclone
    sshfs
    age
    openssl
    gh
    bottom
    hyperfine
    whois
    tealdeer
    colmena
    sops
    samba
    cifs-utils
    nfs-utils
    tokei
    zip
    unixtools.xxd
    elf-info
    restic
    parallel
    qrcp
    libnotify

    # nix utils
    nurl
    nixpkgs-review
    nixpkgs-fmt
    nix-prefetch
    nix-output-monitor
    nix-init
    nix-tree
    cntr
    bubblewrap
    attic-client

    # networking cli
    wireguard-tools
    mtr
    iproute2
    iptables
    nmap
    tcpdump
    q
    tun2socks
    nali
    tcping-go
    iptraf-ng # TODO: make it setcap
    cloudflare-warp

    # self-packaged cli
    goauthing
    pb
    sharzyscripts

    # tex
    python3.pkgs.pygments
    latexrun
    zathura
    (texlive.combine {
      inherit (texlive) scheme-full;
      pkgFilter = pkg: lib.elem pkg.tlType [ "run" "bin" "doc" ];
    })

    # gui
    telegram-desktop
    snipaste
    zotero
    dropbox
    obsidian
    mpv
    feh
    geeqie
    anki
    thunderbird
    meld
    chromium
    parsec-bin

    # TOTALLY PROPRIETARY
    wpsoffice
    # (mathematica.override rec {
    #   version = "13.3.1";
    #   source = pkgs.requireFile {
    #     name = "Mathematica_${version}_BNDL_LINUX_CN.sh";
    #     sha256 = "1xl6ji8qg6bfz4z72b8czl0cx36fzfkxhygsn0m8xd0qgkkpjqfg";
    #     message = ''
    #       File not found, you can find it in
    #       https://wdm-reborn.itsu.eu.org/Rasis/Mathematica/${version}.0/BNDL_English/
    #     '';
    #     hashMode = "recursive";
    #   };
    # })
    zoom-us

    # ide
    # jetbrains.clion
    # jetbrains.pycharm-professional
    # jetbrains.goland
    # jetbrains.idea-ultimate
    # jetbrains.webstorm
    vscode

    # x cli
    xclip
    pavucontrol
    dconf

    beancount
    subconverter

    typst
  ];
}
