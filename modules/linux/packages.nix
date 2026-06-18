{
  config,
  pkgs,
  lib,
  username,
  ...
}:

{
  home-manager.users.${username}.home.packages =
    lib.optionals config.flags.profiles.graphical [
      pkgs.discord # Messaging platform
      pkgs.discord-ptb # Public Test Build
      pkgs.discord-canary # Bleeding edge
      pkgs.vesktop # Alternate Discord client
      pkgs.thunderbird # Email client

      # Media and graphics
      pkgs.obs-studio # Recording/streaming
      pkgs.haruna # Media player
      pkgs.gimp3-with-plugins # Graphics editor

      # Downloading and torrenting
      pkgs.qbittorrent # Torrent client

      # Browsers
      pkgs.brave # Privacy-focused Chromium-based browser
      pkgs.firefox # Browser by Mozilla
      pkgs.google-chrome # Propietary browser by Google

      # Other
      pkgs.wl-clipboard
      pkgs.papirus-icon-theme # Icon theme
    ]
    ++ lib.optionals config.flags.profiles.development [
      pkgs.jetbrains.idea # Java development
      pkgs.jetbrains.phpstorm # PHP development
      pkgs.jetbrains.rider # .NET development
      pkgs.postman # You know what Postman is
    ]
    ++ lib.optionals (config.hostname == "tigris") [ pkgs.librewolf ]
    ++ [
      pkgs.unar # The Unarchiver
    ];
}
