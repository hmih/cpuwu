let
  pkgs = import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/5bc33ec2d6e0f7d3a3afcf58f5e12f6ec288d14b.tar.gz";
    sha256 = "1646alqc65spdcfmxlq9yfc0c8axv304dhkbjgz78y8azxzfykc6";
  }) { };
in
pkgs.mkShellNoCC {
  packages = with pkgs; [
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
  ];
}
