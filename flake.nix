{
  description = "BrowserOS (Chromium fork) dev shell for NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };

        # Chromium/Depot Tools assume a writable HOME; keep everything in-repo.
        chromiumSrcDir = "\${PWD}/.chromium-src";

        python = pkgs.python312;

        pythonEnv = python.withPackages (ps: with ps; [
          click typer pyyaml requests boto3 python-dotenv pillow cryptography
        ]);
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            git git-lfs
            pythonEnv

            # Chromium / GN / Ninja toolchain
            clang lld llvm
            ninja gn
            pkg-config

            # Common Chromium Linux deps (not exhaustive, but a good baseline)
            alsa-lib
            at-spi2-atk at-spi2-core atk cairo cups dbus expat
            fontconfig freetype
            glib
            gtk3
            libdrm
            libxkbcommon
            libX11 libXcomposite libXcursor libXdamage libXext libXfixes
            libXi libXrandr libXrender libXScrnSaver libXtst
            mesa
            nspr nss
            pango
            pciutils
            pulseaudio
            xorg.libxcb xorg.xcbutil xorg.xcbutilwm xorg.xcbutilimage xorg.xcbutilkeysyms xorg.xcbutilrenderutil
            zlib

            # Helpful for big builds / fetches
            curl unzip rsync
          ];

          # Make Python CLI available as `browseros` once installed editable.
          shellHook = ''
            export CHROMIUM_SRC="${chromiumSrcDir}"
            echo "CHROMIUM_SRC=$CHROMIUM_SRC"
            echo "Tip: run: (cd packages/browseros && pip install -e .)"
          '';
        };

        # Optional: a `nix build` that produces a packaged artifact is possible,
        # but Chromium builds are very stateful/huge. Start with nix develop.
        packages.default = pkgs.stdenvNoCC.mkDerivation {
          pname = "browseros-placeholder";
          version = "0.0.0";
          src = self;
          installPhase = ''
            mkdir -p $out
            echo "Use: nix develop, then run browseros build/package inside the shell." > $out/README
          '';
        };
      });
}
