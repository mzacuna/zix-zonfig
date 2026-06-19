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
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.lists) singleton;
  inherit (lib.strings) hasSuffix;
in
mkMerge [
  (optionalAttrs (hasSuffix "-darwin" system) (
    mkIf config.flags.profiles.graphical {
      # That's it.
      homebrew.casks = singleton "helium-browser";
    }
  ))

  (optionalAttrs (hasSuffix "-linux" system) (
    mkIf config.flags.profiles.graphical (
      let
        inherit (lib.meta) getExe getExe';
        inherit (lib.strings) concatStringsSep toJSON;

        bundleId = "net.imput.helium";

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

        helium = inputs.helium.packages.${system}.default;
      in
      {
        environment.etc."chromium/policies/managed/policies.json".text = toJSON policy;

        home-manager.users.${username} =
          { lib, ... }:
          {
            home = {
              packages = singleton helium;

              activation.heliumPreferences = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                prefs="$HOME/.config/${bundleId}/Default/Preferences"
                if [ ! -e "$prefs" ]; then
                  $DRY_RUN_CMD mkdir -p "$(dirname "$prefs")"
                  $DRY_RUN_CMD install -m600 ${preferencesJson} "$prefs"
                fi
              '';

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
