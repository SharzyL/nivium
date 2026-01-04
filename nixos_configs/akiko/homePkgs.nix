{ pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # dev
    bear
    qemu
    man-pages
    flamegraph
    radare2
    rustfmt
    python3 # tide needs it to work TODO: fix

    # media and doc cli
    imagemagick
    pandoc
    ffmpeg
    poppler-utils
    syncplay
    handbrake
    calibre
    flac
    shntool
    cuetools
    picard
    sox
    audacity
    mediainfo
    lame
    logchecker
    # torrenttools

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
    yt-dlp
    hyperfine
    whois
    samba
    cifs-utils
    nfs-utils
    tokei
    smartmontools
    babelfish
    unixtools.xxd
    elf-info
    restic
    parallel
    (lib.lowPrio moreutils)
    python3Packages.afdko # Adobe Font Development Kit for OpenType
    qrcp
    # mlc
    p7zip
    android-tools
    beancount
    subconverter
    go-grip

    git-filter-repo
    git-absorb
    git-revise

    # nix utils
    sops
    nurl
    nixpkgs-review
    nixpkgs-fmt
    nix-prefetch
    nix-output-monitor
    nix-init
    cntr
    bubblewrap
    nix-tree
    attic-client
    nvfetcher
    colmena

    # wine
    winePackages.full
    winetricks
    dxvk

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

    # self-packaged things
    goauthing
    pb
    sharzyscripts
    music-tag
    sharzyscripts
    csync
    rdict
    gh

    # tex
    python3.pkgs.pygments-extra
    latexrun
    zathura
    (texlive.combine {
      inherit (texlive) scheme-full;
      pkgFilter = pkg: lib.elem pkg.tlType [ "run" "bin" "doc" ];
    })

    typst

    # gui
    sioyek
    telegram-desktop
    snipaste
    zotero
    dropbox
    obsidian
    mpv
    feh
    anki
    thunderbird
    parsec-bin
    chromium
    imhex
    nicotine-plus
    blender
    pavucontrol

    # design
    gimp
    inkscape
    fontforge

    # TOTALLY PROPRIETARY
    wpsoffice
    mathematica
    zoom-us

    # ide
    jetbrains.clion
    jetbrains.rust-rover
    vscode
    claude-code

  ];
}
