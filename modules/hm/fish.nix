{ config, pkgs, lib, ... }:

let
  cfg = config.nivium.fish;
  fish-colored-man = pkgs.srcs.fish-colored-man.src; # TODO: upstream
in
{
  options.nivium.fish = with lib; {
    enable = mkOption { type = types.bool; default = config.nivium.profile != "bare"; };
    extraScript = mkOption { type = types.str; default = ""; };
  };

  config = lib.mkIf cfg.enable {
    programs.man.generateCaches = false;

    programs.fish = {
      enable = true;
      plugins =
        let
          makePlugin = p: { name = p.pname or p.repo; src = p.src or p; };
        in
        map makePlugin (with pkgs.fishPlugins; [
          tide
          fzf-fish
          done
          fish-colored-man
        ]);

      functions = lib.mkMerge [{
        "@has" = "command -v $argv > /dev/null";

        setproxy = ''
          set -l port "$argv[1]"
          export {HTTP,HTTPS,ALL}_PROXY=http://127.0.0.1:$port \
                 {http,https,all}_proxy=http://127.0.0.1:$port
        '';

        unsetproxy = ''
          set -e {http,all,https}_proxy {HTTP,ALL,HTTPS}_PROXY
        '';

        _tide_item_parent = ''
          if [ -n "$FISH_PARENT" ]
              _tide_print_item parent "[$FISH_PARENT]"
          else if [ -n "$IN_NIX_SHELL" ]
              _tide_print_item parent "[nix: $IN_NIX_SHELL]"
          else if [ -n "$pcomm" ]
              _tide_print_item parent "[$pcomm]"
          end
        '';

        gpg-up = ''
          if [ -d $GNUPGHOME ]
            set -gx GPG_TTY (tty)
            set -u SSH_AGENT_PID
            if [ \( -z "$gnupg_SSH_AUTH_SOCK_by" -o "$gnupg_SSH_AUTH_SOCK_by" != "$fish_pid" \) -a -z "$SSH_CONNECTION" ]
                set -gx SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
            end
          end
        '';

        last_history_item = ''
          echo $history[1]
        '';

        bgrun = ''
          $argv 1>>/tmp/nohup.out 2>>/tmp/nohup.err &
          disown
        '';

        where = ''
          realpath (which $argv)
        '';

        delink = ''
          set -l file "$argv[1]"
          mv -i $file $file.bak
          cat $file.bak > $file
        '';

      }
        (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
          sstart = ''
            sudo systemctl restart $argv[1]
            sudo journalctl -efu $argv[1]
          '';

          ustart = ''
            systemctl --user restart $argv[1]
            journalctl --user -efu $argv[1]
          '';
        })
        (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
          sudo = ''
            if test -z "$SSH_CONNECTION";
              ${pkgs.reattach-to-user-namespace}/bin/reattach-to-user-namespace sudo $argv
            else
              sudo $argv
            end
          '';
        })];

      shellAbbrs = lib.mkMerge [
        (
          let
            latexmkArgs = "-shell-escape -interaction=nonstopmode -file-line-error -synctex=1";
          in
          {
            svi = "sudo -E nvim";

            lkb = "latexmk ${latexmkArgs} -xelatex";
            lks = "latexmk ${latexmkArgs} -xelatex -pvc";
            lkbl = "latexmk ${latexmkArgs} -lualatex";
            lksl = "latexmk ${latexmkArgs} -lualatex -pvc";

            nss = "nix-shell --command fish";
            nr = "nix repl";
            nrp = "nix repl nixpkgs#legacyPackages.(nix eval --impure --raw --expr 'builtins.currentSystem')";
            ne = "nix-env";
            nd = "nix develop --command fish";
            nb = "nix build --no-link --print-out-paths";
            cola = "colmena apply --verbose --on";

            p = "prevd";

            zp = "zpool";

            # always be cautious for an action that may delete a file
            mv = "mv -i";
            cp = "cp -i";
            rm = "rm -i";

            js = "just";

            bear = "noproxy bear";
            pn = "pnpm";
          }
        )
        (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
          ip = "ip -c";
          xc = "wl-copy --trim-newline";

          stl = "systemctl";
          sstl = "sudo systemctl";
          ustl = "systemctl --user";
          jtl = "journalctl";
          sjtl = "sudo journalctl";
          ujtl = "journalctl --user";
        })
      ];
      shellAliases = {
        g = "git";
        ".." = "cd ..";
        "..." = "cd ../..";
        "...." = "cd ../../..";
        "....." = "cd ../../../..";
        "......" = "cd ../../../../..";
        noproxy = "env -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY -u http_proxy -u https_proxy -u all_proxy";
        wget = "wget --hsts-file=${config.xdg.dataHome}/wget-hsts";
        ls = "eza --hyperlink=auto";
        l = "eza -lgF --hyperlink=auto";
        ll = "eza -lgaF --hyperlink=auto";
        la = "eza -lgaaF --hyperlink=auto";
        lt = "eza -gTF --hyperlink=auto";
        lm = "eza -gl --hyperlink=auto --sort=modified";
        rg = "rg --hyperlink-format kitty";
      };

      shellInit =
        let
          tide_conf = "${pkgs.fishPlugins.tide.src}/functions/tide/configure";
        in
        ''
          string replace -r '^' 'set -g ' < ${tide_conf}/icons.fish | source
          string replace -r '^' 'set -g ' < ${tide_conf}/configs/lean.fish | source
          string replace -r '^' 'set -g ' < ${tide_conf}/configs/lean_16color.fish | source

          set -g tide_prompt_add_newline_before true

          set -g tide_left_prompt_items \
            pwd context git newline character
          set -g tide_right_prompt_items \
            status parent cmd_duration jobs node python rustc go time

          set -g fish_color_command blue

          set -g tide_context_always_display true
          set -g tide_context_color_default afb42b
          set -g tide_context_color_root    e64a19
          set -g tide_context_color_ssh     6ff9c1
        '';

      interactiveShellInit = ''
        set -g fish_cursor_default block
        set -g fish_cursor_insert line
        set -g fish_cursor_replace_one underscore
        set -g fish_cursor_visual block

        set -g fish_greeting
        set -g man_standout -r white
        fish_vi_key_bindings
        [ -n "$TMUX" ] && set fish_vi_force_cursor

        abbr -a !! --position anywhere --function last_history_item
        abbr -a ns --set-cursor "nix shell p#%"
        abbr -a cbb --set-cursor "cmake -B build -DCMAKE_BUILD_TYPE=%"
        complete -c bgrun -x -a '(__fish_complete_subcommand)'
        complete -c where -x -a '(complete -C "")'

        # setup tide
        if @has ps && @has xargs
            set ppid (ps -o ppid= -p $fish_pid | xargs)
            test -n $ppid && set -xg pcomm (ps -o comm= -p $ppid)
        end

        set VIRTUAL_ENV_DISABLE_PROMPT true  # prevent venv modifying prompt

        gpg-up

        ${cfg.extraScript}
      '';
    };
  };
}
