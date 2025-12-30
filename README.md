# Nivium

Plural genitive of _nix_. The NixOS and home-manager configuration set to configure Sharzy’s Nix-powered machines.

## Usage

To use NixOS modules,

```console
# nixos-build switch --flake .
```

Or use my own wrapper script of [nix-output-monitor](https://github.com/maralorn/nix-output-monitor),

```console
# nsw
```

The flake path is chosen from the automatically recognized hostname.

To use home-manager,
```console
$ nix run p#home-manager -- --switch --flake .#$(hostname)
```

## Keybindings Allocation

WM (output -> workspace -> window):
- Super prefixed
- `Super+{n}`: focus to workspace
- `Super+shift+{n}`: move to workspace
- `Super+{hjkl}`: navigate panel
- `Super(+Shift)+Tab`: recent window
- `Super+Ctrl(+Shift)+Tab`: recent window by app_id

Applications:
   - Kitty (tab -> window):
      - `Ctrl+K`: prefixed
      - `Ctrl+K+{n}`: focus to tab
      - `Ctrl+K {<>}`: move tab
      - `Ctrl+M`: interactively focus to window
      - `Ctrl+K {hjkl}`: navigate window
      - `Ctrl+K Shift+{hjkl}`: move window
      - NeoVim (window / buffer):
         - `Alt+{n}`: focus to buffer
         - `Ctrl+Comma/Stop`: navigate buffer
         - `<leader> b`: interactively select buffer
         - `Ctrl+W {hjkl}`: navigate window
         - `<leader> {hjkl}`: navigate window
   - Firefix Sideberry (panel -> tab):
      - `Alt+{n}` focus to panel
      - `Alt+F{n}` focus to tab in panel
      - `Ctrl+Tab` focus to tab in panel
      - `Ctrl+Shift+{n}` move to panel

Fcitx
- `Alt+Shift+{n}` switch to IME
