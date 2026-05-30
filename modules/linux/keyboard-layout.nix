{
  config,
  lib,
  inputs,
  ...
}:

lib.mkIf config.flags.profiles.graphical {
  services.xserver.xkb.extraLayouts = {
    tangent_qwerty = {
      description = "Tangent QWERTY layout";
      languages = [
        "eng"
        "spa"
      ];
      symbolsFile = "${inputs.tangent}/xkb/symbols/tangent_qwerty";
    };
    kuntem_jq = {
      description = "Kuntem-JQ layout";
      languages = [
        "eng"
        "spa"
      ];
      symbolsFile = "${inputs.tangent}/xkb/symbols/kuntem_jq";
    };
  };

  services.keyd.enable = true;
  environment.etc."keyd/default.conf".source = "${inputs.tangent}/keyd/default.conf";
}
