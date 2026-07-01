{ config, lib, ... }:

lib.mkIf config.flags.profiles.ai {
  homebrew.casks = [
    "codex-app"
    "t3-code"
  ];
}
