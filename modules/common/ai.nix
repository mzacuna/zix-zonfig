{
  config,
  lib,
  username,
  ...
}:

lib.mkIf config.flags.profiles.development {
  home-manager.users.${username} =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # Managed settings for Claude Code's settings.json. Changes to these
      # keys are overwritten on rebuild. Keys not listed here are left
      # untouched, so new keys persist across rebuilds.
      settings = {
        model = "opus";
        effortLevel = "xhigh";
        theme = "auto";
        alwaysThinkingEnabled = true;
        attribution = {
          commit = "";
          pr = "";
        };
        includeCoAuthoredBy = false; # deprecated
      };

      settingsPath = "${config.programs.claude-code.configDir}/settings.json";
    in
    {
      programs.codex.enable = true;

      programs.claude-code = {
        enable = true;
        package = pkgs.claude-code;
      };

      home.packages = [ pkgs.claude-agent-acp ];

      home.activation.claudeCodeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        _path="${settingsPath}"
        _declared=${lib.escapeShellArg (builtins.toJSON settings)}

        # A regular file may hold keys Claude added itself — keep them. A
        # read-only store symlink from a prior generation has nothing worth
        # keeping (it was unwritable), so drop it and rebuild from scratch.
        _existing='{}'
        if [ -L "$_path" ]; then
          $DRY_RUN_CMD rm -f "$_path"
        elif [ -f "$_path" ]; then
          _read="$(${pkgs.jq}/bin/jq -c . "$_path" 2>/dev/null || true)"
          if [ -n "$_read" ]; then _existing="$_read"; fi
        fi

        # Declared keys win; every other key already in the file is preserved.
        _merged="$(printf '%s' "$_existing" | ${pkgs.jq}/bin/jq \
          --argjson declared "$_declared" \
          '(. * $declared)
           + { "$schema": "https://json.schemastore.org/claude-code-settings.json" }' \
          2>/dev/null || true)"

        # Only write when the merge produced something, so a transient error
        # never clobbers a good file with an empty one.
        if [ -n "$_merged" ]; then
          mkdir -p "$(dirname "$_path")"
          _tmp="$(mktemp)"
          printf '%s\n' "$_merged" > "$_tmp"
          chmod 600 "$_tmp"
          $DRY_RUN_CMD mv "$_tmp" "$_path"
        fi
      '';
    };
}
