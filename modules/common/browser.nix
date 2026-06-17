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
  inherit (lib.attrsets)
    genAttrs
    mapAttrs'
    mapAttrsToList
    nameValuePair
    optionalAttrs
    ;
  inherit (lib.generators) toPlist;
  inherit (lib.lists) singleton;
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkAfter mkIf mkMerge;
  inherit (lib.strings) concatStringsSep hasSuffix toJSON;
  inherit (lib.trivial) const;

  isDarwin = hasSuffix "-darwin" system;
  isLinux = hasSuffix "-linux" system;

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

  seedPreferences = rel: ''
    prefs="$HOME/${rel}"
    if [ ! -e "$prefs" ]; then
      $DRY_RUN_CMD mkdir -p "$(dirname "$prefs")"
      $DRY_RUN_CMD install -m600 ${preferencesJson} "$prefs"
    fi
  '';
in
mkMerge [
  (optionalAttrs isDarwin (
    mkIf config.flags.profiles.graphical (
      let
        managedDir = "/Library/Managed Preferences";

        managedPrefs = {
          ${bundleId} = policy;
        }
        // (
          policy."3rdparty".extensions
          |> mapAttrs' (id: prefs: nameValuePair "${bundleId}.extensions.${id}" prefs)
        );

        # Build a domain's plist in the store, and the cp line that installs it.
        copyPlist =
          domain: prefs:
          ''cp -f ${
            pkgs.writeText "${domain}.plist" (toPlist { escape = true; } prefs)
          } "${managedDir}/${domain}.plist"'';
      in
      {
        homebrew.casks = singleton "helium-browser";

        # Relaunch Helium or killall cfprefsd to pick up changes.
        system.activationScripts.postActivation.text = mkAfter ''
          mkdir -p "${managedDir}"
          ${managedPrefs |> mapAttrsToList copyPlist |> concatStringsSep "\n"}
        '';

        home-manager.users.${username} =
          { lib, ... }:
          {
            home.activation.heliumPreferences = lib.hm.dag.entryAfter [ "writeBoundary" ] (
              seedPreferences "Library/Application Support/${bundleId}/Default/Preferences"
            );
          };
      }
    )
  ))

  (optionalAttrs isLinux (
    mkIf config.flags.profiles.graphical (
      let
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
                seedPreferences ".config/helium/Default/Preferences"
              );

              sessionVariables = {
                BROWSER = getExe helium;
                DEFAULT_BROWSER = getExe helium;
              };
            };

            xdg.mimeApps.defaultApplications = genAttrs [
              "text/html"
              "application/xhtml+xml"
              "x-scheme-handler/http"
              "x-scheme-handler/https"
              "x-scheme-handler/about"
              "x-scheme-handler/unknown"
            ] (const "helium.desktop");
          };
      }
    )
  ))
]
