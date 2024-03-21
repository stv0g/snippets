{
  description = "Application packaged using poetry2nix";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-utils,
    poetry2nix,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      poetry2nix = inputs.poetry2nix.lib.mkPoetry2Nix {inherit pkgs;};
      inherit (poetry2nix) mkPoetryApplication defaultPoetryOverrides;
    in {
      packages = {
        push-status = mkPoetryApplication {
          projectDir = self;
          overrides =
            defaultPoetryOverrides.extend
            (self: super: {
              uptime-kuma-api =
                super.uptime-kuma-api.overridePythonAttrs
                (
                  old: {
                    buildInputs = (old.buildInputs or []) ++ [super.setuptools];
                  }
                );
            });
        };
        default = self.packages.${system}.push-status;
      };

      devShells.default = pkgs.mkShell {
        inputsFrom = [self.packages.${system}.push-status];
        packages = [pkgs.poetry];
      };
    });
}
