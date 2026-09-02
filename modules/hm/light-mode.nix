{ config, lib, pkgs, ... }:

let
  cfg = config.nivium;

  # Coldark-Cold rather than OneHalfLight: OneHalfLight paints some scopes with its
  # own background color (#fafafa), and delta highlights every hunk without the
  # surrounding file context, so the nix syntax puts '=' and ';' into one of those
  # scopes and they come out invisible. Coldark-Cold keeps every scope dark.
  lightSyntaxTheme = "Coldark-Cold";

  # bat's own default, named explicitly so that the dark side is a theme name too:
  # $BAT_THEME is also what delta takes its syntax theme from, and delta has no
  # notion of bat's special "light"/"dark" values -- it would warn on every diff
  # and fall back to its default.
  darkSyntaxTheme = "Monokai Extended";

  # the single script, not pkgs.sharzyscripts.sysutils: the group would drag
  # every other sysutil (and its runtime inputs) into the closure of every
  # generation that uses this module
  termBg = "${pkgs.sharzyscripts.term-bg}/bin/term-bg";

  # fzf's own "light" base scheme is readable, but its accents are unrelated to
  # everything else here; these are the onedark light palette, as used for kitty
  # below. Only the entries that carry meaning are overridden, the base scheme
  # keeps the rest sane.
  fzfLightColors = lib.concatStringsSep "," [
    "fg+:#383a42"
    "bg+:#dcdcdc"
    "hl:#a626a4"
    "hl+:#a626a4"
    "prompt:#4078f2"
    "pointer:#e45649"
    "marker:#50a14f"
    "spinner:#0184bc"
    "header:#0184bc"
    "info:#818387"
    "border:#818387"
  ];
in
{
  options.nivium.lightMode = lib.mkEnableOption ''
    a light color scheme for the local GUI, which for now means kitty's palette.
    Command line tools are deliberately not covered: they are just as often run
    from a remote session, whose terminal may have any background, so they follow
    the terminal itself and fall back to $TERM_THEME_OVERRIDE where it cannot be asked
  '';

  config = lib.mkMerge [
    {
      # bat, delta and nvim each ask the terminal for its background color on
      # their own (OSC 10/11 plus a DA1 or DSR terminator). Nothing light or dark
      # is pinned for them here, because this config is also what a remote
      # session on this host reads, and its terminal may be either -- and for
      # delta specifically, setting `light` or `dark` turns its detection off.
      # The fish side below still hands them the session's answer, so that a
      # terminal which stays silent does not leave them disagreeing with the
      # prompt.

      # bat is already added to home.packages in base.nix
      programs.bat = {
        enable = true;
        config = {
          # auto: pick by querying the terminal. When the terminal does not
          # answer, bat falls back to its own default theme rather than to
          # theme-dark, which is why theme-dark below is that same default.
          theme = "auto";
          theme-light = lightSyntaxTheme;
          theme-dark = darkSyntaxTheme;
        };
      };

      # delta detects light and dark itself, but has no environment variable for
      # it, so DELTA_FEATURES plus these named features is how the fish side
      # tells it what the rest of the session settled on.
      programs.git.settings.delta = {
        lightmode.light = true;
        darkmode.dark = true;
      };

      # Everything that cannot ask the terminal itself is fed from one term-bg
      # call, cached per tty: every query costs a round trip to the terminal,
      # which over ssh is not free, and every fish spawned would pay it.
      programs.fish.functions = {
        # __nivium_export NAME [VALUE...] -- export NAME, or erase it when the
        # value is empty, so that going back to dark leaves no trace
        __nivium_export = ''
          set -l name $argv[1]
          set -l value $argv[2..-1]
          if test -n "$value"
              set -gx $name $value
          else
              set -e $name
          end
        '';

        # __nivium_color NAME [VALUE...] -- set a fish color, remembering what it
        # was the first time so it can be put back; with no VALUE, put it back
        __nivium_color = ''
          set -l name $argv[1]
          set -l saved __nivium_saved_$name
          set -q $saved || eval "set -g $saved \$$name"
          if test (count $argv) -gt 1
              set -g $name $argv[2..-1]
          else
              eval "set -g $name \$$saved"
          end
        '';

        __nivium_bg_cache = ''
          set -l dir "$XDG_RUNTIME_DIR"
          test -z "$dir" && set dir /tmp
          echo "$dir/nivium-term-bg"(id -u)(tty 2>/dev/null | string replace -a / _)
        '';

        __nivium_term_bg = ''
          if set -q TERM_THEME_OVERRIDE
              echo $TERM_THEME_OVERRIDE
              return
          end
          set -l cache (__nivium_bg_cache)
          if test -f "$cache"
              cat "$cache"
              return
          end
          # Only an interactive shell may ask: tide renders the prompt in a child
          # fish, and querying there would take the terminal out from under the
          # shell that is reading the user's keys.
          if not status is-interactive
              echo dark
              return
          end
          set -l bg (${termBg} 2>/dev/null)
          test -z "$bg" && set bg dark
          printf '%s\n' $bg >"$cache" 2>/dev/null
          echo $bg
        '';

        __nivium_apply_theme = ''
          set -l bg (__nivium_term_bg)

          # Remember what was in place before we touched anything, so that going
          # back to dark restores it rather than guessing at defaults. The fzf one
          # is exported: a fish started from an already themed fish would
          # otherwise capture our own export and take it for the user's. The tide
          # colors are not exported, so a nested shell re-reads ./fish.nix's.
          set -q __nivium_fzf_base || set -gx __nivium_fzf_base $FZF_DEFAULT_OPTS
          set -q __nivium_tide_base || set -g __nivium_tide_base \
              $tide_context_color_default $tide_context_color_root $tide_context_color_ssh

          if test "$bg" = light
              __nivium_export FZF_DEFAULT_OPTS $__nivium_fzf_base --color=light,${fzfLightColors}

              # the tide context widget (user@host), darkened for a light
              # background while keeping the hues from ./fish.nix
              set -g tide_context_color_default 6f6614
              set -g tide_context_color_root    bf360c
              set -g tide_context_color_ssh     00695c

              # fish's default theme paints these with the bright ANSI colors,
              # which are the pale end of a light palette (brcyan is 2.3:1 on
              # #fafafa). Values are the onedark light palette, as for kitty.
              __nivium_color fish_color_error e45649
              __nivium_color fish_color_escape 0997b3
              __nivium_color fish_color_operator 0997b3
              __nivium_color fish_color_user 50a14f
              __nivium_color fish_color_search_match --background=dcdcdc
              __nivium_color fish_color_selection --background=dcdcdc

              # bat and delta can ask the terminal themselves, but a session
              # whose terminal stays silent would then disagree with everything
              # above. Hand them this session's answer: it is per session, so a
              # shell reached from another terminal still gets its own.
              __nivium_export BAT_THEME "${lightSyntaxTheme}"
              __nivium_export DELTA_FEATURES +lightmode
          else
              __nivium_export FZF_DEFAULT_OPTS $__nivium_fzf_base
              set -g tide_context_color_default $__nivium_tide_base[1]
              set -g tide_context_color_root    $__nivium_tide_base[2]
              set -g tide_context_color_ssh     $__nivium_tide_base[3]
              for name in error escape operator user search_match selection
                  __nivium_color fish_color_$name
              end
              __nivium_export BAT_THEME "${darkSyntaxTheme}"
              __nivium_export DELTA_FEATURES +darkmode
          end

          # nvim asks the terminal too, but its answer only arrives after the
          # first redraw, so the colorscheme is loaded twice and the window
          # visibly flips. Hand it what we already know, before it draws.
          __nivium_export TERM_THEME_DETECTED $bg
        '';

        retheme = {
          description = "re-detect the terminal background, or pin it";
          body = ''
            # retheme [light|dark] -- pin this terminal, for one that cannot
            # answer an OSC 11 query; with no argument, drop the pin and ask again
            set -l mode
            test (count $argv) -gt 0 && set mode $argv[1]
            set -l cache (__nivium_bg_cache)
            switch "$mode"
                case light dark
                    set -gx TERM_THEME_OVERRIDE $mode
                    printf '%s\n' $mode >"$cache" 2>/dev/null
                case ""
                    set -e TERM_THEME_OVERRIDE
                    rm -f "$cache"
                case "*"
                    echo "retheme: expected light, dark, or no argument" >&2
                    return 2
            end
            __nivium_apply_theme
          '';
        };
      };

      # shellInit, not interactiveShellInit: tide computes the prompt in a child
      # fish, which re-sources config.fish and is not interactive, so it would
      # otherwise fall back to the dark tide colors from ./fish.nix while the
      # interactive shell's own variables were right. mkAfter puts this after
      # those defaults.
      programs.fish.shellInit = lib.mkAfter ''
        __nivium_apply_theme
      '';
    }

    (lib.mkIf cfg.lightMode {
      # Only the local GUI belongs here. Command line tools are left to their own
      # detection, since the same host is also reached over ssh from terminals
      # that are not this one.

      # the rest of kitty is handled in ./kitty.nix
      programs.kitty.settings = {
        # the OneHalfLight terminal palette
        background = "#fafafa";
        foreground = "#383a42";
        cursor = "#383a42";
        cursor_text_color = "#fafafa";
        selection_background = "#dcdcdc";
        selection_foreground = "#383a42";
        url_color = "#0184bc";

        color0 = "#383a42";
        color1 = "#e45649";
        color2 = "#50a14f";
        color3 = "#c18401";
        color4 = "#0184bc";
        color5 = "#a626a4";
        color6 = "#0997b3";
        color7 = "#fafafa";
        color8 = "#4f525e";
        color9 = "#e06c75";
        color10 = "#98c379";
        color11 = "#e5c07b";
        color12 = "#61afef";
        color13 = "#c678dd";
        color14 = "#56b6c2";
        color15 = "#ffffff";

        active_border_color = "#a0a1a7";
        inactive_border_color = "#dcdcdc";

        # same tab bar as in ./kitty.nix, in the onedark light palette
        tab_title_template =
          "\"{fmt.fg._dcdcdc}{fmt.bg.default}"
          + "{fmt.fg._383a42}{fmt.bg._dcdcdc}{index}"
          + "{fmt.fg._383a42} {title[:20]}"
          + "{fmt.fg._a626a4}{'' if num_windows == 1 else ' *' + str(num_windows)}"
          + "{fmt.fg._dcdcdc}{fmt.bg.default} \"";
        active_tab_title_template = "\"{fmt.fg._e2c792}{fmt.bg.default}"
          + "{fmt.fg._4078f2}{fmt.bg._e2c792}{index}"
          + "{fmt.fg._383a42} {title[:20]}"
          + "{fmt.fg._a626a4}{'' if num_windows == 1 else ' *' + str(num_windows)}"
          + "{fmt.fg._7c5c20}{'' if layout_name == 'splits' else 'Z' if layout_name == 'stack' else '/' + layout_name}"
          + "{fmt.fg._e2c792}{fmt.bg.default} \"";
      };
    })
  ];
}
