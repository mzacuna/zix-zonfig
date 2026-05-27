{
  config,
  pkgs,
  lib,
  ...
}:

lib.mkIf config.isDev {
  home-manager.sharedModules = [
    {
      programs.codex.enable = true;

      programs.claude-code = {
        enable = true;

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

      home.packages = [ pkgs.claude-agent-acp ];
    }
  ];
}
