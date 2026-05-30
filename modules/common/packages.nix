{
  config,
  pkgs,
  lib,
  ...
}:

{
  home-manager.sharedModules = [
    {
      home.packages = [
        pkgs.file # File type identifier
        pkgs.wget # Get files over network
        pkgs.tree # File system tree visualizer
        pkgs.killall # Kill all
        pkgs.fd # Modern alternative to 'find'
        pkgs.ripgrep # Modern alternative to 'grep'
        pkgs.jc # Converts many outputs to JSON
        pkgs.fzf # Fuzzy finder
        pkgs.rage # Encryption tool
        pkgs.nh # nixos/darwin-rebuild wrapper with closure diffs
      ]
      ++ lib.optionals config.flags.profiles.interactive [
        pkgs.ffmpeg
        pkgs.yt-dlp
        pkgs.ragenix
      ]
      ++ lib.optionals config.flags.profiles.development [
        pkgs.nixfmt # Nix formatter
        pkgs.nixd # Nix language server
        pkgs.gopls # Go language server
        pkgs.basedpyright # Python language server
      ];
    }
  ];
}
