{
  config,
  pkgs,
  inputs,
  username,
  ...
}:

let
  home = config.users.users.${username}.home;
  configPath = "Documents/kanata-tangent-config.kbd";
in
{
  homebrew.casks = [ "karabiner-elements" ];

  environment.systemPackages = [ pkgs.kanata ];

  home-manager.users.${username}.home = {
    file."${configPath}".source = "${inputs.tangent}/mac/kanata.kbd";

    shellAliases.kanata-restart = "sudo launchctl kickstart -k system/org.nixos.kanata";
  };

  launchd.daemons.kanata.serviceConfig = {
    ProgramArguments = [
      "/run/current-system/sw/bin/kanata"
      "--cfg"
      "${home}/${configPath}"
    ];
    RunAtLoad = true;
    KeepAlive = true;
    StandardOutPath = "/var/log/kanata.log";
    StandardErrorPath = "/var/log/kanata.log";
  };
}
