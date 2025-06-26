{
  description = "A development shell for Haskell projects";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?rev=11cb3517b3af6af300dd6c055aeda73c9bf52c48";
    flake-utils.url = "github:numtide/flake-utils";

  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        haskell-overlay = final: prev: {
          # Make stack use nix provided compiler and system libraries
          stack = prev.stack.overrideAttrs (old: {
            nativeBuildInputs = old.nativeBuildInputs ++ [ prev.makeWrapper ];
            postInstall = ''
              wrapProgram $out/bin/stack \
                --add-flags '--nix --no-nix-pure --nix-path="nixpkgs=${pkgs.path}"'
            '';
          });

          ghc-with-batteries = pkgs.haskell.packages.ghc928.ghcWithHoogle (hpkgs: with hpkgs; [ ]);
        };
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ haskell-overlay ];
        };
      in
      {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            cabal-install
            ghc-with-batteries
            ghcid
            fourmolu
          ];
          # Set up a shell hook for environment variables or commands to run on entry
          shellHook = ''
            echo "Entering Haskell development shell..."
            echo "GHC version: $(ghc --version)"
            echo "Cabal version: $(cabal --version)"
            echo "Haskell Language Server version: $(haskell-language-server --version)"
          '';
        };
        formatter = pkgs.nixpkgs-fmt;
      }
    );
}

/*
        # Haskell Language Server for IDE features
        haskellPackages.haskell-language-server
        # Cabal for building Haskell projects
        haskellPackages.cabal-install
        # The Glasgow Haskell Compiler
        haskellPackages.ghc
        # GHCi watcher for quick feedback
        haskellPackages.ghcid
        # Haskell linter for code quality
        haskellPackages.hlint
        # Brittany for Haskell code formatting
        haskellPackages.brittany
        # Stylish Haskell for more Haskell code formatting
        haskellPackages.stylish-haskell
*/
