{
  config,
  pkgs,
  lib,
  username,
  ...
}:

lib.mkIf config.flags.profiles.development {
  home-manager.users.${username} = {
    programs = {
      codex.enable = true;

      claude-code = {
        enable = true;
        package = pkgs.claude-code;

        settings = {
          model = "opus";
          alwaysThinkingEnabled = true;
          effortLevel = "xhigh";

          theme = "auto";

          attribution = {
            commit = "";
            pr = "";
          };

          # Deprecated
          includeCoAuthoredBy = false;
        };
      };
    };

    home.packages = [ pkgs.claude-agent-acp ];
  };
}
