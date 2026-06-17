{
  description = "Multi-host Nix config";

  nixConfig = {
    extra-experimental-features = [ "pipe-operators" ];
    extra-substituters = [ "https://nix-community.cachix.org" ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helium = {
      url = "github:amaanq/helium-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };

    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    homebrew-emacs-builds = {
      url = "github:jimeh/homebrew-emacs-builds";
      flake = false;
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tangent = {
      url = "github:mzacuna/tangent";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      nix-darwin,
      nix-homebrew,
      ...
    }:
    let
      lib = nixpkgs.lib.extend (import ./lib/util.nix);

      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-darwin"
        "x86_64-linux"
      ];

      specialArgsFor =
        {
          host,
          username,
          system,
        }:
        {
          inherit
            inputs
            lib
            system
            username
            ;
          hostname = host;
        };

      sharedModules = host: [
        ./lib/options.nix
        ./modules/common
        (./hosts + "/${host}")

        (
          { hostname, username, ... }:
          {
            inherit hostname username;
          }
        )

        (
          { ... }:
          {
            nixpkgs.overlays = [
              inputs.claude-code.overlays.default
              inputs.emacs-overlay.overlays.default
            ];
          }
        )

        (
          { ... }:
          {
            hosts = [
              "acheron"
              "nile"
              "tigris"
            ];
          }
        )
      ];

      mkNixos =
        {
          host,
          username ? "martin",
          system ? "x86_64-linux",
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = specialArgsFor { inherit host username system; };
          modules = sharedModules host ++ [
            ./modules/linux
            inputs.home-manager.nixosModules.home-manager

            inputs.agenix.nixosModules.default
          ];
        };

      mkDarwin =
        {
          host,
          username ? "martin",
          system ? "aarch64-darwin",
        }:
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = specialArgsFor { inherit host username system; };
          modules = sharedModules host ++ [
            ./modules/darwin
            home-manager.darwinModules.home-manager
            nix-homebrew.darwinModules.nix-homebrew
            inputs.agenix.darwinModules.default
          ];
        };
    in
    {
      nixosConfigurations = {
        acheron = mkNixos { host = "acheron"; };
        tigris = mkNixos { host = "tigris"; };
      };

      darwinConfigurations = {
        nile = mkDarwin { host = "nile"; };
      };

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
