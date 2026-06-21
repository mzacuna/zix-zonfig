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
    mapAttrs'
    mapAttrsToList
    nameValuePair
    optionalAttrs
    ;
  inherit (lib.generators) toPlist;
  inherit (lib.lists) singleton;
  inherit (lib.meta) getExe getExe';
  inherit (lib.modules) mkAfter mkIf mkMerge;
  inherit (lib.strings) concatStringsSep hasSuffix toJSON;

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
        daemonName = "helium-managed-prefs";

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

        applyPolicies = pkgs.writeShellScript daemonName ''
          set -eu
          mkdir -p "${managedDir}"
          ${managedPrefs |> mapAttrsToList copyPlist |> concatStringsSep "\n"}
        '';

        helium-policy-probe =
          pkgs.runCommandCC "helium-policy-probe" { meta.mainProgram = "helium-policy-probe"; }
            ''
              mkdir -p "$out/bin"
              cc -O2 -Wall -framework CoreFoundation -o "$out/bin/helium-policy-probe" ${pkgs.writeText "helium-policy-probe.c" ''
                #include <CoreFoundation/CoreFoundation.h>
                #include <stdio.h>

                static int is_forced(CFStringRef key, CFStringRef app) {
                    return CFPreferencesAppValueIsForced(key, app) ? 1 : 0;
                }

                int main(void) {
                    CFStringRef app = CFSTR("${bundleId}");
                    CFPreferencesAppSynchronize(app); /* pull fresh state from cfprefsd */
                    int fl = is_forced(CFSTR("ExtensionInstallForcelist"), app);
                    int se = is_forced(CFSTR("DefaultSearchProviderSearchURL"), app);
                    printf("Helium managed policy (${bundleId}):\n");
                    printf("  force-install:   %s\n", fl ? "ON " : "OFF");
                    printf("  default search:  %s\n", se ? "ON " : "OFF");
                    if (fl && se)
                        printf("  Policy served: YES\n");
                    else if (!fl && !se)
                        printf("  Policy served: NO\n");
                    else
                        printf("  Mixed: one key forced, the other not, re-run to confirm.\n");
                    /* Exit reflects force-install only: that is the data-loss axis the tools
                       gate on. Search is informational; both keys live in one plist and move
                       together, so a real split is not expected. */
                    return fl ? 0 : 1;
                }
              ''}
            '';

        probeBin = getExe helium-policy-probe;

        extensionIds = concatStringsSep " " policy.ExtensionInstallForcelist;

        quitHeliumFn = ''
          quit_helium() {
            if pgrep -x Helium >/dev/null 2>&1; then
              echo "quitting Helium..."
              osascript -e 'quit app "Helium"' 2>/dev/null || pkill -x Helium || true
              i=0
              while [ "$i" -lt 20 ]; do
                pgrep -x Helium >/dev/null 2>&1 || break
                sleep 0.5
                i=$((i + 1))
              done
            fi
          }
        '';

        # Snapshot the force-installed extensions' chrome.storage + IndexedDB, per profile.
        helium-backup = pkgs.writeScriptBin "helium-backup" ''
          #!/bin/sh
          set -u

          ROOT="''${HELIUM_PROFILE_DIR:-$HOME/Library/Application Support/${bundleId}}"
          DEST="''${HELIUM_BACKUP_DIR:-$HOME/.local/state/helium-backups}"
          PROBE="''${HELIUM_PROBE:-${probeBin}}"
          KEEP=14
          DO_QUIT=0
          FORCE=0

          IDS="${extensionIds}"

          while [ $# -gt 0 ]; do
            case "$1" in
              --quit)  DO_QUIT=1 ;;
              --force) FORCE=1 ;;
              --dest)  [ $# -ge 2 ] || { echo "--dest needs an argument"; exit 2; }; DEST="$2"; shift ;;
              --keep)  [ $# -ge 2 ] || { echo "--keep needs an argument"; exit 2; }; KEEP="$2"; shift ;;
              --list)  find "$DEST" -maxdepth 1 -type d -name '[0-9]*-[0-9]*' 2>/dev/null | sort -r; exit 0 ;;
              *) echo "unknown arg: $1"; exit 2 ;;
            esac
            shift
          done

          case "$KEEP" in "" | *[!0-9]*) echo "--keep must be a non-negative integer"; exit 2 ;; esac
          [ -d "$ROOT" ] || { echo "No Helium profile dir at $ROOT"; exit 1; }

          ${quitHeliumFn}
          # Health gate: a snapshot taken while the policy is off could capture a wiped
          # state and, via rotation, bury the last good one.
          if [ "$FORCE" -ne 1 ]; then
            if ! "$PROBE" >/dev/null 2>&1; then
              echo "SKIP: force-install policy not in effect; not risking a good backup."
              echo "Re-run with --force to override."
              exit 0
            fi
          fi

          [ "$DO_QUIT" -eq 1 ] && quit_helium

          STAMP="$(date +%Y%m%d-%H%M%S)"
          TMP="$DEST/.tmp-$STAMP-$$"
          SNAP="$DEST/$STAMP"
          mkdir -p "$TMP" || { echo "could not create $TMP"; exit 1; }

          copied=0
          for profile in "$ROOT"/Default "$ROOT"/Profile\ *; do
            [ -d "$profile" ] || continue
            pname="$(basename "$profile")"
            for id in $IDS; do
              for store in "Local Extension Settings" "Sync Extension Settings"; do
                src="$profile/$store/$id"
                [ -e "$src" ] || continue
                dst="$TMP/$pname/$store"
                mkdir -p "$dst"
                cp -R "$src" "$dst/" && copied=$((copied + 1))
              done
              for idb in "$profile"/IndexedDB/chrome-extension_"$id"_*; do
                [ -e "$idb" ] || continue
                dst="$TMP/$pname/IndexedDB"
                mkdir -p "$dst"
                cp -R "$idb" "$dst/" && copied=$((copied + 1))
              done
            done
          done

          if [ "$copied" -eq 0 ]; then
            echo "nothing to back up (no extension data found under $ROOT)."
            rm -rf "$TMP"
            exit 0
          fi

          { echo "snapshot: $STAMP"; echo "source:   $ROOT"; echo "items:    $copied dir(s)"; date; } > "$TMP/manifest.txt"

          mv "$TMP" "$SNAP" || { echo "could not publish snapshot to $SNAP"; rm -rf "$TMP"; exit 1; }
          echo "snapshot $STAMP  ($copied dir(s), $(du -sh "$SNAP" 2>/dev/null | cut -f1))  ->  $SNAP"

          # Rotation: keep the newest $KEEP timestamped snapshots (pre-restore-* survive).
          find "$DEST" -maxdepth 1 -type d -name '[0-9]*-[0-9]*' 2>/dev/null | sort -r | {
            n=0
            while IFS= read -r d; do
              n=$((n + 1))
              [ "$n" -gt "$KEEP" ] && { rm -rf "$d"; echo "  rotated out: $(basename "$d")"; }
            done
          }

          exit 0
        '';

        # Restore a snapshot's data into a live profile.
        helium-restore = pkgs.writeScriptBin "helium-restore" ''
          #!/bin/sh
          set -u

          ROOT="''${HELIUM_PROFILE_DIR:-$HOME/Library/Application Support/${bundleId}}"
          DEST="''${HELIUM_BACKUP_DIR:-$HOME/.local/state/helium-backups}"
          PROBE="''${HELIUM_PROBE:-${probeBin}}"
          FORCE=0
          ASSUME_YES=0
          DO_QUIT=1
          SNAP=""

          IDS="${extensionIds}"

          while [ $# -gt 0 ]; do
            case "$1" in
              --list)    find "$DEST" -maxdepth 1 -type d -name '[0-9]*-[0-9]*' 2>/dev/null | sort -r; exit 0 ;;
              --force)   FORCE=1 ;;
              --yes)     ASSUME_YES=1 ;;
              --no-quit) DO_QUIT=0 ;;
              -*) echo "unknown arg: $1"; exit 2 ;;
              *)  SNAP="$1" ;;
            esac
            shift
          done

          [ -n "$SNAP" ] || SNAP="$(find "$DEST" -maxdepth 1 -type d -name '[0-9]*-[0-9]*' 2>/dev/null | sort -r | head -n 1)"
          { [ -n "$SNAP" ] && [ -d "$SNAP" ]; } || { echo "no snapshot found in $DEST. Pass a path, or run helium-backup first."; exit 1; }

          # Restore puts data back INTO an existing profile; it does not rebuild
          # one. No "Local State" means no real profile and restoring would just
          # scatter orphan dirs. (--force overrides.)
          if [ "$FORCE" -ne 1 ] && [ ! -e "$ROOT/Local State" ]; then
            echo "no live Helium profile at: $ROOT"
            echo "helium-restore only restores extension DATA into an existing profile. Restore"
            echo "the whole profile from your factory-reset backup, or open Helium once to make a"
            echo "fresh one (the policy reinstalls the extensions), then re-run."
            exit 1
          fi

          echo "restoring from: $SNAP"
          [ -f "$SNAP/manifest.txt" ] && sed 's/^/  /' "$SNAP/manifest.txt"

          # The policy must be applied or the restore gets garbage-collected on
          # next launch.
          if [ "$FORCE" -ne 1 ] && ! "$PROBE" >/dev/null 2>&1; then
            echo
            echo "REFUSING: force-install policy not in effect. Restoring now just gets the data"
            echo "deleted again on launch. Re-apply first:"
            echo "  helium-policy-apply"
            echo "Then re-run, or use --force."
            exit 1
          fi

          if [ "$ASSUME_YES" -ne 1 ]; then
            echo
            printf 'This overwrites current extension data with the snapshot. Type RESTORE: '
            read -r reply
            [ "$reply" = "RESTORE" ] || { echo "aborted."; exit 1; }
          fi

          ${quitHeliumFn}
          [ "$DO_QUIT" -eq 1 ] && quit_helium

          # Undo point: save the current data before overwriting it.
          PRE="$DEST/pre-restore-$(date +%Y%m%d-%H%M%S)"
          echo "saving current state to $PRE (undo) ..."
          for profile in "$ROOT"/Default "$ROOT"/Profile\ *; do
            [ -d "$profile" ] || continue
            pname="$(basename "$profile")"
            for id in $IDS; do
              for store in "Local Extension Settings" "Sync Extension Settings"; do
                src="$profile/$store/$id"; [ -e "$src" ] || continue
                dst="$PRE/$pname/$store"; mkdir -p "$dst"; cp -R "$src" "$dst/"
              done
              for idb in "$profile"/IndexedDB/chrome-extension_"$id"_*; do
                [ -e "$idb" ] || continue
                dst="$PRE/$pname/IndexedDB"; mkdir -p "$dst"; cp -R "$idb" "$dst/"
              done
            done
          done

          restored=0
          for pdir in "$SNAP"/*/; do
            [ -d "$pdir" ] || continue
            pname="$(basename "$pdir")"
            for store in "Local Extension Settings" "Sync Extension Settings" "IndexedDB"; do
              sdir="$pdir$store"
              [ -d "$sdir" ] || continue
              mkdir -p "$ROOT/$pname/$store"
              for item in "$sdir"/*; do
                [ -e "$item" ] || continue
                base="$(basename "$item")"
                rm -rf "$ROOT/$pname/$store/$base"
                cp -R "$item" "$ROOT/$pname/$store/" && restored=$((restored + 1))
              done
            done
          done

          echo
          echo "restored $restored item(s) from $(basename "$SNAP")."
          echo "undo: previous state saved at $PRE"
          [ "$DO_QUIT" -eq 1 ] && echo "now reopen Helium."

          exit 0
        '';

        helium-policy-apply = pkgs.writeScriptBin "helium-policy-apply" ''
          #!/bin/sh
          set -u

          PROBE="''${HELIUM_PROBE:-${probeBin}}"
          MANAGED="${managedDir}/${bundleId}.plist"

          applied() { "$PROBE" >/dev/null 2>&1; }

          if applied; then
            echo "already applied — the policy is in effect, nothing to do."
            "$PROBE" | sed -n '2,5p'
            exit 0
          fi

          echo "policy is OFF; re-applying (you'll be asked for your password)..."

          # Write the managed plist by running the exact script the boot daemon runs — its
          # store path is baked in by Nix, so there is no plist to parse and nothing to go
          # stale. (The boot daemon wraps this in wait4path; here the store is already up.)
          echo "  - writing the managed plist..."
          sudo ${applyPolicies}
          if [ ! -e "$MANAGED" ]; then
            echo "FAILED to write $MANAGED."
            exit 1
          fi
          echo "  - managed plist is present."

          echo "  - nudging ManagedClient + cfprefsd..."
          sudo killall ManagedClient cfprefsd 2>/dev/null || true
          sleep 3

          if applied; then
            echo
            echo "APPLIED. Restore your data with:  helium-restore"
            exit 0
          fi

          echo
          echo "Still OFF after nudge. The plist is on disk now, so a reboot should potentially apply"
          echo "it (ManagedClient scans the now-present file at boot). After rebooting:"
          echo "  helium-policy-probe     # expect: force-install ON"
          echo "  helium-restore          # then restore"
          exit 2
        '';
      in
      {
        homebrew.casks = singleton "helium-browser";

        launchd.daemons.${daemonName}.serviceConfig = {
          RunAtLoad = true;
          StandardErrorPath = "/var/log/helium-managed-prefs.log";
          ProgramArguments = [
            "/bin/sh"
            "-c"
            "/bin/wait4path /nix/store && exec ${applyPolicies}"
          ];
        };

        # Daily 20:00 snapshot of the extensions' data
        launchd.user.agents.helium-backup.serviceConfig = {
          ProgramArguments = singleton <| getExe helium-backup;
          StartCalendarInterval = {
            Hour = 20;
            Minute = 0;
          };
          StandardOutPath = "/Users/${username}/Library/Logs/helium-backup.log";
          StandardErrorPath = "/Users/${username}/Library/Logs/helium-backup.log";
          EnvironmentVariables.PATH = "/usr/bin:/bin:/usr/sbin:/sbin";
        };

        system.activationScripts.postActivation.text = mkAfter ''
          consoleUser="$(/usr/bin/stat -f%Su /dev/console)"
          if [ -n "$consoleUser" ] && [ "$consoleUser" != "root" ]; then
            /usr/bin/sudo -u "$consoleUser" ${getExe pkgs.defaultbrowser} helium
          fi
        '';

        home-manager.users.${username} =
          { lib, ... }:
          {
            home.packages = [
              helium-policy-probe
              helium-backup
              helium-restore
              helium-policy-apply
            ];

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
        # Helium reads Chromium's managed-policy path on Linux.
        environment.etc."chromium/policies/managed/policies.json".text = toJSON policy;

        home-manager.users.${username} =
          { lib, ... }:
          {
            home = {
              packages = singleton helium;

              activation.heliumPreferences = lib.hm.dag.entryAfter [ "writeBoundary" ] (
                seedPreferences ".config/${bundleId}/Default/Preferences"
              );

              # Merge defaults into mimeapps.list.
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
