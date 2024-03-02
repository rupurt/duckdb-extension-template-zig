{
  description = "DuckDB extension template for Zig";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    zig-overlay = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    duckdb-nix = {
      url = "github:rupurt/duckdb-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    flake-utils,
    nixpkgs,
    zig-overlay,
    duckdb-nix,
    ...
  }: let
    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    outputs = flake-utils.lib.eachSystem systems (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          zig-overlay.overlays.default
          duckdb-nix.overlay
        ];
      };
      buildInputs =
        [
          pkgs.pkg-config
          pkgs.gnumake
          pkgs.zigpkgs.master
        ]
        ++ pkgs.lib.optionals (pkgs.stdenv.isLinux) [
          pkgs.libcxx
        ];
      devShellPackages =
        [
        ]
        ++ pkgs.lib.optionals (pkgs.stdenv.isLinux) [
          pkgs.strace
          pkgs.valgrind
        ];
    in {
      # packages exported by the flake
      packages = {};

      # nix run
      apps = {};

      # nix fmt
      formatter = pkgs.alejandra;

      # nix develop -c $SHELL
      devShells = rec {
        # nix develop .#main -c $SHELL
        main = pkgs.mkShell.override {stdenv = pkgs.libcxxStdenv;} {
          name = "main dev shell";

          buildInputs = buildInputs;

          packages =
            [
              pkgs.duckdb-pkgs.main
            ]
            ++ devShellPackages;
        };

        # nix develop .#v0-10-0 -c $SHELL
        v0-10-0 = pkgs.mkShell.override {stdenv = pkgs.libcxxStdenv;} {
          name = "v0.10.0 dev shell";

          buildInputs = buildInputs;

          packages =
            [
              pkgs.duckdb-pkgs.duckdb-v0_10_0
            ]
            ++ devShellPackages;
        };

        # nix develop .#v0-9-2 -c $SHELL
        v0-9-2 = pkgs.mkShell.override {stdenv = pkgs.libcxxStdenv;} {
          name = "v0.9.2 dev shell";

          buildInputs = buildInputs;

          packages =
            [
              pkgs.duckdb-pkgs.duckdb-v0_9_2
            ]
            ++ devShellPackages;
        };

        # nix develop .#nixpkgs-duckdb -c $SHELL
        nixpkgs-duckdb = pkgs.mkShell.override {stdenv = pkgs.libcxxStdenv;} {
          name = "nixpkgs duckdb dev shell";

          buildInputs = buildInputs;

          packages =
            [
              pkgs.duckdb
            ]
            ++ devShellPackages;
        };

        # nix develop -c $SHELL
        default = v0-9-2;
      };
    });
  in
    outputs;
}
