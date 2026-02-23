{
  description = "linear-cli - Linear issue tracker CLI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      version = "1.10.0";

      # Map nix system strings to release archive names
      archiveNames = {
        "aarch64-darwin" = "aarch64-apple-darwin";
        "x86_64-darwin" = "x86_64-apple-darwin";
        "aarch64-linux" = "aarch64-unknown-linux-gnu";
        "x86_64-linux" = "x86_64-unknown-linux-gnu";
      };

      hashes = {
        "aarch64-darwin" = "sha256-gpxeAIKLgmc+UXTtFFME6pra5MElj7frWbGNSJQk7Ak=";
        "x86_64-darwin" = "sha256-5HccJyxSjrCJbvEABBImfbgFDbLRiyP4HOFMylbR+DA=";
        "aarch64-linux" = "sha256-QhBfvG5T67x3zpVVkcTPx+WL2+5niMYXbmoq/Hx2fko=";
        "x86_64-linux" = "sha256-UZUYUkcHmh/cCM2xAxAeJrG1sdBj1fTB2n7HknjTdVg=";
      };

      supportedSystems = builtins.attrNames archiveNames;

      forEachSystem = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          archiveName = archiveNames.${system};
        in
        {
          default = pkgs.stdenvNoCC.mkDerivation {
            pname = "linear-cli";
            inherit version;

            src = pkgs.fetchurl {
              url = "https://github.com/schpet/linear-cli/releases/download/v${version}/linear-${archiveName}.tar.xz";
              hash = hashes.${system};
            };

            nativeBuildInputs =
              [ pkgs.xz ]
              ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.autoPatchelfHook ];

            buildInputs = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
              pkgs.stdenv.cc.cc.lib
            ];

            sourceRoot = "linear-${archiveName}";

            installPhase = ''
              install -Dm755 linear $out/bin/linear
            '';

            meta = {
              description = "Linear issue tracker CLI - list, start, and create PRs for Linear issues";
              homepage = "https://github.com/schpet/linear-cli";
              license = pkgs.lib.licenses.mit;
              platforms = supportedSystems;
              mainProgram = "linear";
            };
          };
        }
      );
    };
}
