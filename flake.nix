{
  description = "cpuwu — FPGA dev environment (GateMate A1)";

  inputs = {
    nixpkgs.url = "git+file:///Users/hmih/fun/nixology/nixpkgs";
  };

  outputs = { self, nixpkgs }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];

      mkPkgs = system: import nixpkgs { inherit system; };

      mkDevShell = system:
        let pkgs = mkPkgs system;
        in pkgs.mkShellNoCC {
          packages = with pkgs; [
            # general tools
            gnumake
            gh
            jq
            git
            less
            vim
            tree
            which
            shfmt
            markdownlint-cli
            yamlfmt
            curl
            graphviz
            # simulation & verification
            verilator
            iverilog
            gtkwave
          ];

          # FPGA tools come from vendor/oss-cad-suite (OSS CAD Suite)
          # GateMate: yosys, nextpnr-himbaechel, gmpack, openFPGALoader
          shellHook = ''
            if [ -f vendor/oss-cad-suite/environment ]; then
              . vendor/oss-cad-suite/environment
              echo "OSS CAD Suite loaded — GateMate toolchain ready."
            else
              echo "WARNING: vendor/oss-cad-suite not found. FPGA tools unavailable."
              echo "  Download: https://github.com/YosysHQ/oss-cad-suite-build/releases"
            fi
          '';
        };

      mkPackage = system:
        let pkgs = mkPkgs system;
        in pkgs.stdenvNoCC.mkDerivation {
          pname = "cpuwu";
          version = "0.1.0";
          src = ./. ;  # includes vendor/ (not filtered by gitignore like self)
          nativeBuildInputs = with pkgs; [ gnumake ];
          buildPhase = ''
            runHook preBuild
            if [ ! -f vendor/oss-cad-suite/environment ]; then
              echo "ERROR: vendor/oss-cad-suite not found."
              echo "  curl -LO https://github.com/YosysHQ/oss-cad-suite-build/releases"
              exit 1
            fi
            . vendor/oss-cad-suite/environment
            make
            runHook postBuild
          '';
          installPhase = ''
            runHook preInstall
            mkdir -p $out
            cp gen/hello.bit $out/
            runHook postInstall
          '';
        };
    in
    {
      devShells = forAllSystems (system: {
        default = mkDevShell system;
      });

      packages = forAllSystems (system: {
        default = mkPackage system;
      });
    };
}
