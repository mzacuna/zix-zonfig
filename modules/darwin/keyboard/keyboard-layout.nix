{ inputs, username, ... }:

{
  homebrew.casks = [ "ukelele" ];

  home-manager.users.${username} =
    { lib, ... }:
    {
      home.activation.installKeylayout = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "$HOME/Library/Keyboard Layouts"
        cp -f ${inputs.tangent}/mac/Tangent-Gallium.keylayout "$HOME/Library/Keyboard Layouts/Tangent Gallium.keylayout"
        cp -f ${inputs.tangent}/mac/Kuntem-JQ.keylayout "$HOME/Library/Keyboard Layouts/Kuntem-JQ.keylayout"
      '';
    };
}
