{
  description = "Fast, keyboard-first desktop file manager";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages.${system}.default = pkgs.flutter344.buildFlutterApplication {
        pname = "waydir";
        version = "0.23.0";
        src = self;

        pubspecLock = builtins.fromJSON (builtins.readFile ./pubspec.lock.json);
        customSourceBuilders = {
          sqlite3_flutter_libs = { src, ... }: src;
          sqlcipher_flutter_libs = { src, ... }: src;
        };

        nativeBuildInputs = [
          pkgs.autoPatchelfHook
          pkgs.copyDesktopItems
        ];

        buildInputs = [
          pkgs.stdenv.cc.cc.lib
          pkgs.xz
        ];

        desktopItems = [
          (pkgs.makeDesktopItem {
            name = "waydir";
            desktopName = "Waydir";
            genericName = "File Manager";
            comment = "Fast, keyboard-first desktop file manager";
            exec = "waydir %U";
            icon = "waydir";
            categories = [
              "System"
              "FileTools"
              "FileManager"
            ];
            mimeTypes = [ "inode/directory" ];
            startupNotify = true;
          })
        ];

        postInstall = ''
          install -Dm644 linux/packaging/deb/waydir.png \
            $out/share/icons/hicolor/512x512/apps/waydir.png
        '';

        meta = {
          description = "Fast, keyboard-first desktop file manager";
          homepage = "https://github.com/mikolajbadyl/waydir";
          license = pkgs.lib.licenses.mit;
          mainProgram = "waydir";
          platforms = [ system ];
          sourceProvenance = with pkgs.lib.sourceTypes; [ binaryNativeCode ];
        };
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pkgs.flutter344
          pkgs.cargo
          pkgs.rustc
          pkgs.rustfmt
          pkgs.clippy
          pkgs.pkg-config
          pkgs.gtk3
        ];
      };
    };
}
