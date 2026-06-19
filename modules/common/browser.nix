{
  config,
  inputs,
  lib,
  pkgs,
  system,
  username,
  ...
}:

let
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.lists) singleton;
  inherit (lib.meta) getExe getExe';
  inherit (lib.modules) mkAfter mkIf mkMerge;
  inherit (lib.strings) concatStringsSep hasSuffix toJSON;

  isDarwin = hasSuffix "-darwin" system;
  isLinux = hasSuffix "-linux" system;

  bundleId = "net.imput.helium";

  preferences = {
    helium.completed_onboarding = true;
    helium.services.user_consented = true;

    helium.browser.layout = 2; # Vertical tabs.
    helium.browser.rounded_frame = false;
    helium.browser.new_tab_next_to_active = true;

    bookmark_bar.show_on_all_tabs = true;
    download.prompt_for_download = true; # Ask where to save each download.
  };

  preferencesJson = pkgs.writeText "helium-preferences.json" (toJSON preferences);

  seedPreferences = rel: ''
    prefs="$HOME/${rel}"
    if [ ! -e "$prefs" ]; then
      $DRY_RUN_CMD mkdir -p "$(dirname "$prefs")"
      $DRY_RUN_CMD install -m600 ${preferencesJson} "$prefs"
    fi
  '';
in
mkMerge [
  # The subset of declarative macOS config I managed to get to work reliably.
  (optionalAttrs isDarwin (
    mkIf config.flags.profiles.graphical {
      homebrew.casks = singleton "helium-browser";

      system.activationScripts.postActivation.text = mkAfter ''
        consoleUser="$(/usr/bin/stat -f%Su /dev/console)"
        if [ -n "$consoleUser" ] && [ "$consoleUser" != "root" ]; then
          /usr/bin/sudo -u "$consoleUser" ${getExe pkgs.defaultbrowser} helium
        fi
      '';

      home-manager.users.${username} =
        { lib, ... }:
        {
          home.activation.heliumPreferences = lib.hm.dag.entryAfter [ "writeBoundary" ] (
            seedPreferences "Library/Application Support/${bundleId}/Default/Preferences"
          );
        };
    }
  ))

  (optionalAttrs isLinux (
    mkIf config.flags.profiles.graphical (
      let
        ublockId = "blockjmkbacgjkknlgpkjjiijinjdanf";
        ublock = {
          toOverwrite.filters = [
            # Shorts open in the normal /watch player.
            ''||youtube.com/shorts/$document,uritransform=/^https:\/\/(?:www\.|m\.)?youtube\.com\/shorts\/([^\/?#]+)/https:\/\/www.youtube.com\/watch?v=$1/''
          ];

          userSettings = [
            [
              "userFiltersTrusted"
              "true"
            ]
          ];
        };

        policy = {
          DefaultBrowserSettingEnabled = false; # Don't prompt to set as default.
          BatterySaverModeAvailability = 0; # Never throttle background tabs.
          DeveloperToolsAvailability = 1; # Always allow devtools.

          DefaultSearchProviderEnabled = true;
          DefaultSearchProviderName = "Kagi";
          DefaultSearchProviderSearchURL = "https://kagi.com/search?q={searchTerms}";
          DefaultSearchProviderSuggestURL = "https://kagi.com/api/autosuggest?q={searchTerms}";
          SearchSuggestEnabled = true;

          # Force-installed extensions (uBO is bundled by Helium).
          ExtensionInstallForcelist = [
            "mnjggcdmjocbbbhaepdhchncahnbgone" # SponsorBlock
            "jinjaccalgkegednnccohejagnlnfdag" # Violentmonkey
            "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader
            "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
            "cdglnehniifkbagbbombnjghhcihifij" # Kagi Search
          ];

          "3rdparty".extensions.${ublockId} = ublock;
        };

        helium = inputs.helium.packages.${system}.default;
      in
      {
        environment.etc."chromium/policies/managed/policies.json".text = toJSON policy;

        home-manager.users.${username} =
          { lib, ... }:
          {
            home = {
              packages = singleton helium;

              activation.heliumPreferences = lib.hm.dag.entryAfter [ "writeBoundary" ] (
                seedPreferences ".config/${bundleId}/Default/Preferences"
              );

              # Merge defaults into mimeapps.list
              activation.heliumMimeDefaults =
                let
                  desktop = "helium.desktop";
                  types = [
                    "text/html"
                    "application/xhtml+xml"
                    "x-scheme-handler/http"
                    "x-scheme-handler/https"
                    "x-scheme-handler/about"
                    "x-scheme-handler/unknown"
                  ];
                in
                lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                  run ${getExe' pkgs.xdg-utils "xdg-mime"} default ${desktop} ${concatStringsSep " " types}
                '';

              sessionVariables = {
                BROWSER = getExe helium;
                DEFAULT_BROWSER = getExe helium;
              };
            };
          };
      }
    )
  ))
]
