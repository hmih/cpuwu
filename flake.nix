{
  description = "cpuwu — FPGA dev environment (ECP5 / ULX3S)";

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

      # ── Dev shell: all interactive tools ──────────────────────────────────
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
            graphviz            # for `make view` (yosys show)
            # fpga toolchain
            yosys
            nextpnr
            trellis
            openfpgaloader
            # simulation & verification
            verilator
            iverilog
            gtkwave
            haskellPackages.sv2v
          ];
        };

      # ── Package: reproducible bitstream build ─────────────────────────────
      mkPackage = system:
        let pkgs = mkPkgs system;
        in pkgs.stdenvNoCC.mkDerivation {
          pname = "cpuwu";
          version = "0.1.0";
          src = self;
          nativeBuildInputs = with pkgs; [
            gnumake
            yosys
            nextpnr
            trellis
          ];
          buildPhase = ''
            runHook preBuild
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
