{
  config,
  pkgs,
  lib,
  ...
}:

lib.mkIf config.flags.profiles.graphical {
  home-manager.sharedModules = [
    {
      programs.vscodium = {
        enable = true;
        profiles.default.extensions = [
          pkgs.vscode-extensions.mkhl.direnv
          pkgs.vscode-extensions.rust-lang.rust-analyzer
          pkgs.vscode-extensions.jnoortheen.nix-ide
          pkgs.vscode-extensions.dracula-theme.theme-dracula
        ];
      };
    }
  ];
}
