{ config, inputs, pkgs, ... }:

{
  imports = [
    inputs.hermes-agent.nixosModules.default
  ];

  # dotenv-style KEY=VALUE lines for hermes-agent
  sops.secrets."hermes_env" = { sopsFile = ../../../secrets/akiko.yaml; };

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;
    # expects DEEPSEEK_API_KEY, OHMYGPT_API_KEY, DISCORD_BOT_TOKEN, DISCORD_ALLOWED_USERS
    environmentFiles = [ config.sops.secrets."hermes_env".path ];
    environment = {
      DISCORD_HOME_CHANNEL = "1557648855615672330";
    };
    # tools for the agent, on its PATH
    extraPackages = with pkgs; [
      python3
      uv
      poppler-utils
      nodejs
      pnpm
      gh
      sqlite
      p7zip # 7z; _7zz only provides 7zz
      pandoc
      ffmpeg
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
  # the module keeps stateDir and workspace at 2770 hermes:hermes; the default
  # ACL keeps files created by group members (umask 022) writable by hermes
  systemd.tmpfiles.rules = [
    "a+ ${config.services.hermes-agent.workingDirectory} - - - - default:group::rwX,default:mask::rwX,default:other::---"
  ];

  # lets sharzy edit the workspace through ~/ws/hermes
  users.users."sharzy".extraGroups = [ "hermes" ];
  home-manager.users."sharzy".systemd.user.tmpfiles.rules = [
    "L %h/ws/hermes - - - - ${config.services.hermes-agent.workingDirectory}"
  ];
}
