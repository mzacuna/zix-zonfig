{
  config,
  inputs,
  username,
  ...
}:

let
  homebrewEnv = {
    HOMEBREW_NO_ANALYTICS = "1";
    HOMEBREW_NO_ENV_HINTS = "1";
    HOMEBREW_NO_UPDATE_REPORT_NEW = "1";
  };
in
{
  homebrew = {
    enable = true;

    taps = builtins.attrNames config.nix-homebrew.taps;

    onActivation = {
      cleanup = "uninstall";
      extraEnv = homebrewEnv;
    };
    global.autoUpdate = false;
  };

  nix-homebrew = {
    enable = true;

    user = username;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "jimeh/homebrew-emacs-builds" = inputs.homebrew-emacs-builds;
    };
    mutableTaps = false;
  };

  environment.variables = homebrewEnv;
}
