{ config, lib, ... }:

lib.mkIf config.flags.profiles.interactive {
  home-manager.sharedModules = [
    {
      programs.git = {
        enable = true;

        settings = {
          user = {
            name = "Martín Zamorano";
            email = "martin@mzamorano.com";
          };

          init.defaultBranch = "main";
          color.ui = "auto";
          pull.rebase = false;

          alias = {
            "a" = "add";
            "aa" = "add -A";
            "s" = "status";
            "d" = "diff";
            "co" = "checkout";
            "br" = "branch";
            "cf" = "commit"; # commit full; as in, a full message
            "cc" = "commit -m"; # commit concise
            "unstage" = "restore --staged";
            "unstage-all" = "restore --staged :/";
            "last" = "log -1 HEAD";
            "lg" =
              "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
          };
        };

        ignores = [
          ".idea"
          ".direnv"
          ".envrc"
          ".env"
          "*~"
          ".fuse_hidden*"
          ".directory"
          ".Trash-*"
          ".nfs*"
          "nohup.out"
          ".DS_Store"
          ".AppleDouble"
          ".LSOverride"
          "Icon"
          "._*"
          "Thumbs.db"
          ".Spotlight-V100"
          ".Trashes"
        ];
      };
    }
  ];
}
