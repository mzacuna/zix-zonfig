{
  config,
  pkgs,
  lib,
  ...
}:

lib.mkIf config.flags.profiles.graphical {
  home-manager.sharedModules = [
    {
      home.sessionVariables =
        let
          browserPath = "${pkgs.firefox}/bin/firefox";
        in
        {
          BROWSER = browserPath;
          DEFAULT_BROWSER = browserPath;
        };

      xdg.mimeApps = {
        enable = true;
        defaultApplications =
          let
            browser = "firefox.desktop";
            videoPlayer = "org.kde.haruna.desktop";
          in
          {
            # Default browser
            "text/html" = browser;
            "x-scheme-handler/http" = browser;
            "x-scheme-handler/https" = browser;
            "x-scheme-handler/about" = browser;
            "x-scheme-handler/unknown" = browser;

            # Video files
            "video/mp4" = videoPlayer;
            "video/x-msvideo" = videoPlayer; # .avi
            "video/quicktime" = videoPlayer; # .mov
            "video/x-matroska" = videoPlayer; # .mkv
            "video/webm" = videoPlayer;
            "video/x-flv" = videoPlayer;
            "video/x-ms-wmv" = videoPlayer;
            "application/x-matroska" = videoPlayer;
          };
      };
    }
  ];
}
