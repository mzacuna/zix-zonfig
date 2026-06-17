{
  config,
  lib,
  username,
  ...
}:

lib.mkIf config.flags.profiles.graphical {
  home-manager.users.${username} = {
    xdg.mimeApps = {
      enable = true;

      defaultApplications =
        let
          videoPlayer = "org.kde.haruna.desktop";
        in
        {
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
  };
}
