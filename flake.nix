{
  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };
  outputs = { nixpkgs, flake-utils, ... }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
      };
      platformer-game = (with pkgs; stdenv.mkDerivation {
          dontpatchshebangs = false;
          pname = "3d-slicer";
          version = "5.8.0";
          src = fetchgit {
            url = "https://github.com/Slicer/Slicer";
            rev = "v5.8.0";
            sha256 = "sha256-u8Z7/4j7/M/sSI+HQAd0FLOJCNcBxQF9ftzKOcCKiSM=";
            fetchSubmodules = true;
          };

          env = {
            CMAKE_TLS_VERIFY = 0;
            EP_EXECUTE_DISABLE_CAPTURE_OUTPUTS = 1;
          };

          buildInputs = [
            # Mandatory
            qt5.full
            xorg.libXt
            git
            openssl
            perl
            libffi
            libGL

            # Needs testing...
            xorg.libXinerama

            # Taken apart from superbuild
            python314
          ];

          nativeBuildInputs = [
            #gcc
            ninja
            cmake
          ];

          buildPhase = ''
            cd ..
            sed '1c\#!/usr/bin/bash' Utilities/SetupForDevelopment.sh > Utilities/SetupForDevelopment.sh
            mkdir Slicer-SuperBuild-Debug && cd Slicer-SuperBuild-Debug
            cmake -S .. \
               -DSlicer_USE_SYSTEM_LibFFI=ON \
               -DSlicer_USE_PYTHONQT=OFF
            make
          '';
          installPhase = ''
            mv Slicer-build/Slicer $out/bin
          '';

          # Specify content hash of fixed derivation output
          outputHashAlgo = "sha256";
          outputHashMode = "recursive";
          outputHash = "";
        }
      );
    in rec {
      defaultApp = flake-utils.lib.mkApp {
        drv = defaultPackage;
      };
      defaultPackage = platformer-game;
      devShell = pkgs.mkShell {
        buildInputs = [
         platformer-game
        ];
      };
    }
  );
}
