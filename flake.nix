{
  description = "linear-cli - Linear issue tracker CLI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      version = "2.4.0";

      # Map nix system strings to release archive names
      archiveNames = {
        "aarch64-darwin" = "aarch64-apple-darwin";
        "x86_64-darwin" = "x86_64-apple-darwin";
        "aarch64-linux" = "aarch64-unknown-linux-gnu";
        "x86_64-linux" = "x86_64-unknown-linux-gnu";
      };

      hashes = {
        "aarch64-darwin" = "sha256-qJTbeJ+vaDPsy6veaB4rzypKzUW9ASMgW/jWvRumkF0=";
        "x86_64-darwin" = "sha256-Z7X9/Q0voMWwFJONuxopgD4ZXzWIOfhMttjSySaitiU=";
        "aarch64-linux" = "sha256-PEgztfQbHbIg7uhxS5JYBG1ey8OWMYvzWg6FOI872aY=";
        "x86_64-linux" = "sha256-msMLoMdc3SUDMDuIMVW9xYjBr4q67rJ1QJG4jNoIksc=";
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
              ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.makeWrapper ];

            sourceRoot = "linear-${archiveName}";

            # Deno standalone binaries embed JS at the end of the ELF.
            # patchelf corrupts the embedded payload, and invoking via
            # ld.so breaks /proc/self/exe which Deno uses to locate it.
            # Instead, keep the binary untouched and wrap it to set
            # LD_LIBRARY_PATH so it can find libstdc++ at runtime.
            installPhase =
              if pkgs.stdenv.hostPlatform.isLinux then
                ''
                  install -Dm755 linear $out/libexec/linear
                  makeWrapper $out/libexec/linear $out/bin/linear \
                    --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ]}"
                ''
              else
                ''
                  install -Dm755 linear $out/bin/linear
                '';

            dontFixup = true;

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
