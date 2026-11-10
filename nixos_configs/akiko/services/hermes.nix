{ config, inputs, pkgs, ... }:

{
  imports = [
    inputs.hermes-agent.nixosModules.default
  ];

  # dotenv-style KEY=VALUE lines for hermes-agent
  sops.secrets."hermes_env" = { sopsFile = ../../../secrets/akiko.yaml; };

  services.hermes-agent = {
    enable = true;
    # the flake's default is `full`, 16 optional extras (local whisper,
    # dingtalk, feishu, bedrock, ...); messaging ships discord and is 0.7 GiB
    # smaller. The pm-pinned ffmpeg is a 432 MiB static binary fetched by
    # URL; nixpkgs' headless one is cached and is only a PATH entry.
    package = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.messaging.override (prev: {
      pmPackages = prev.pmPackages // { ffmpeg = pkgs.ffmpeg-headless; };
    });
    addToSystemPackages = true;
    # expects DEEPSEEK_API_KEY, OHMYGPT_API_KEY, DISCORD_BOT_TOKEN, DISCORD_ALLOWED_USERS
    environmentFiles = [ config.sops.secrets."hermes_env".path ];
    environment = {
      DISCORD_HOME_CHANNEL = "1557648855615672330";
    };
    # tools for the agent, on its PATH (the wrapper already adds node, ffmpeg,
    # ripgrep, git and ssh)
    extraPackages = with pkgs; [
      python3
      uv
      poppler-utils
      pnpm
      gh
      sqlite
      p7zip # 7z; _7zz only provides 7zz
      pandoc
      imagemagick
    ];
    settings = {
      model = {
        provider = "deepseek";
        default = "deepseek-flash";
      };
      # switch with `/model custom:ohmygpt:<model>`
      providers.ohmygpt = {
        api = "https://api.ohmygpt.com/v1";
        key_env = "OHMYGPT_API_KEY";
        transport = "chat_completions";
        discover_models = false;
        models = [
          "gemini-3.8-flash"
          "gemini-3.5-flash-lite"
          "gemini-3.1-pro-preview"
          "grok-4.5"
          "glm-5.2"
        ];
      };
      discord = {
        require_mention = true;
        auto_thread = true;
        reactions = true;
      };
      display = {
        # cap on the first-line preview of a tool call, instead of the built-in 40
        tool_preview_length = 200;
        # show the whole multi-line command block
        platforms.discord.tool_progress = "verbose";
      };
      group_sessions_per_user = true;
    };
  };
  systemd.services.hermes-agent.environment = {
    HTTPS_PROXY = "http://127.0.0.1:1094";
    HTTP_PROXY = "http://127.0.0.1:1094";
  };
  # the module's ProtectSystem=strict only opens stateDir and the workspace; the
  # mihomo config (0640 hermes:hermes, set by hand) is edited by the agent.
  # mihomo reads a LoadCredential snapshot, so a write only lands on restart.
  systemd.services.hermes-agent.serviceConfig.ReadWritePaths = [
    config.nivium.services.mihomo.configFile
  ];
  # the module keeps stateDir and workspace at 2770 hermes:hermes; the default
  # ACL keeps files created by group members (umask 022) writable by hermes
  systemd.tmpfiles.rules = [
    "a+ ${config.services.hermes-agent.workingDirectory} - - - - default:group::rwX,default:mask::rwX,default:other::---"
  ];
  # the module also puts HERMES_HOME at 2770, but hermes refuses some commands
  # when its home is writable by another user. tmpfiles keeps the first line it
  # sees for a path: this file sorts before 00-nixos.conf, so the module's line
  # is dropped, and the resetup after every switch undoes the module's chmod.
  systemd.tmpfiles.settings."00-hermes-home"."${config.services.hermes-agent.stateDir}/.hermes".d = {
    mode = "2750";
    user = config.services.hermes-agent.user;
    group = config.services.hermes-agent.group;
  };

  # lets sharzy edit the workspace through ~/ws/hermes
  users.users."sharzy".extraGroups = [ "hermes" ];
  home-manager.users."sharzy".systemd.user.tmpfiles.rules = [
    "L %h/ws/hermes - - - - ${config.services.hermes-agent.workingDirectory}"
  ];
}
