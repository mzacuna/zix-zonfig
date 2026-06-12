{
  config,
  pkgs,
  lib,
  username,
  ...
}:

lib.mkIf config.flags.profiles.graphical {
  home-manager.users.${username} =
    let
      tree-sitter-parsers = grammars: [
        grammars.tree-sitter-css
        grammars.tree-sitter-elisp
        grammars.tree-sitter-go
        grammars.tree-sitter-html
        grammars.tree-sitter-json
        grammars.tree-sitter-json5
        grammars.tree-sitter-latex
        grammars.tree-sitter-make
        grammars.tree-sitter-markdown
        grammars.tree-sitter-nix
        grammars.tree-sitter-python
        grammars.tree-sitter-regex
        grammars.tree-sitter-rust
        grammars.tree-sitter-sql
        grammars.tree-sitter-toml
        grammars.tree-sitter-yaml
      ];
      extraEmacsPackages = epkgs: [
        (epkgs.treesit-grammars.with-grammars (grammars: tree-sitter-parsers grammars))
      ];
    in
    {
      home.packages = [
        (pkgs.emacsWithPackagesFromUsePackage {
          config = ./init.el;
          defaultInitFile = true;
          package = pkgs.emacs-pgtk;
          inherit extraEmacsPackages;
        })
      ];
    };
}
