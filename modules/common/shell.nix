{ config, lib, ... }:

{
  home-manager.sharedModules = [
    {
      home.shell.enableFishIntegration = true;
      home.shellAliases = {
        g = "git";

        "..." = "cd ../..";
        "...." = "cd ../../..";
        "....." = "cd ../../../..";
        "......" = "cd ../../../../..";
      };

      programs.starship = {
        enable = true;
        settings = {
          cmd_duration.min_time = 30000; # 30 seconds
          add_newline = false;
          status.disabled = false;
          directory.truncation_length = 4;
          git_branch.truncation_length = 24;
        };
      };
    }
    (lib.mkIf config.flags.profiles.interactive {
      home.shellAliases = {
        o = "bat --plain";
        p = "bat --plain --paging=auto";
      };
    })
  ];
}
