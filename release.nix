{ nixpkgs ? <nixpkgs>
, systems ? [ "i686-linux" "x86_64-linux" "x86_64-darwin" ]
}:

let
  pkgs = import nixpkgs {};

  version = (builtins.fromJSON (builtins.readFile ./package.json)).version;

  jobset = import ./default.nix {
    inherit pkgs;
    system = builtins.currentSystem;
  };
in
rec {
  inherit (jobset) tarball;

  package = pkgs.lib.genAttrs systems (system:
    (import ./default.nix {
      pkgs = import nixpkgs { inherit system; };
      inherit system;
    }).package.override {
      postInstall = ''
      mkdir -p $out/share/doc/node2nix
      $out/lib/node_modules/node2nix/node_modules/jsdoc/jsdoc.js -R README.md -r lib -d $out/share/doc/node2nix/apidox
      mkdir -p $out/nix-support
      echo "doc api $out/share/doc/node2nix/apidox" >> $out/nix-support/hydra-build-products
    '';
    }
  );

  tests = pkgs.lib.genAttrs systems (system:
    {
      v4 = import ./tests/override-v4.nix {
        pkgs = import nixpkgs { inherit system; };
        inherit system;
      };
      v6 = import ./tests/override-v6.nix {
        pkgs = import nixpkgs { inherit system; };
        inherit system;
      };
      v8 = import ./tests/override-v8.nix {
        pkgs = import nixpkgs { inherit system; };
        inherit system;
      };
      v10 = import ./tests/override-v10.nix {
        pkgs = import nixpkgs { inherit system; };
        inherit system;
      };
      grunt = import ./tests/grunt/override.nix {
        pkgs = import nixpkgs { inherit system; };
        inherit system;
      };
    });

  release = pkgs.releaseTools.aggregate {
    name = "node2nix-${version}";
    constituents = [
      tarball
    ]
    ++ map (system: builtins.getAttr system package) systems
    ++ pkgs.lib.flatten (map (system:
      let
        tests_ = tests."${system}".v4;
      in
      map (name: builtins.getAttr name tests_) (builtins.attrNames tests_)
      ) systems)
    ++ pkgs.lib.flatten (map (system:
      let
        tests_ = tests."${system}".v6;
      in
      map (name: builtins.getAttr name tests_) (builtins.attrNames tests_)
      ) systems)
    ++ pkgs.lib.flatten (map (system:
      let
        tests_ = tests."${system}".v8;
      in
      map (name: builtins.getAttr name tests_) (builtins.attrNames tests_)
      ) systems)
    ++ pkgs.lib.flatten (map (system:
      let
        tests_ = tests."${system}".v10;
      in
      map (name: builtins.getAttr name tests_) (builtins.attrNames tests_)
      ) systems)
    ++ map (system: tests."${system}".grunt) systems;
  };
}
