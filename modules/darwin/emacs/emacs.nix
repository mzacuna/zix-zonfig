{ pkgs, ... }:

let
  emacsPackages = [ pkgs.emacsPackages.jinx ];
in
{
  homebrew.casks = [ "jimeh/emacs-builds/emacs-app" ];

  home-manager.sharedModules = [
    {
      home = {
        file = {
          ".config/emacs/early-init.el".source = ./early-init.el;
          ".config/emacs/init.el".source = ./init.el;
        };

        packages = emacsPackages ++ [
          pkgs.emacs-lsp-booster
        ];
      };
    }
  ];
}
