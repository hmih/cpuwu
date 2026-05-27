{
  description = "cpuwu — FPGA dev environment";

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

      mkDevShell = system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ ];
          };
        in
        pkgs.mkShellNoCC {
          packages = with pkgs; [
            # general tools
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
    in
    {
      devShells = forAllSystems (system: {
        default = mkDevShell system;
      });
    };
}
