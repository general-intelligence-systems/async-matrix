{
  description = "async-matrix — Ruby gem";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
    mine.url = "github:n-at-han-k/flake.nix";
    mine.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, mine, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        lib = mine.lib.${system};

        gemspecFiles = pkgs.runCommand "async-matrix-gemspec" { } ''
          mkdir -p $out/lib/async/matrix
          cp ${./async-matrix.gemspec}          $out/async-matrix.gemspec
          cp ${./lib/async/matrix/version.rb}   $out/lib/async/matrix/version.rb
        '';

        gems = pkgs.bundlerEnv {
          name = "async-matrix-gems";
          ruby = pkgs.ruby_3_4;
          gemfile = ./Gemfile;
          lockfile = ./Gemfile.lock;
          gemset = ./gemset.nix;
          extraConfigPaths = [ "${gemspecFiles}/." ];
        };

      in
      {
        devShells.default = lib.mkRubyShell {
          buildInputs = with pkgs; [
            gems
            gems.wrappedRuby

            rustc
            cargo
            clang
            libclang
          ];

          shellHook = /* bash */ ''
            export LIBCLANG_PATH="${pkgs.libclang.lib}/lib"

            export BUNDLE_GEMFILE="$PWD/Gemfile"
            export BUNDLE_FROZEN=false

            export LANG="''${LANG:-C.UTF-8}"
            export LC_ALL="''${LC_ALL:-$LANG}"

            export RUBYLIB="$PWD/lib''${RUBYLIB:+:$RUBYLIB}"

            if [ -d "$PWD/../async-rest/lib" ]; then
              export RUBYLIB="$PWD/../async-rest/lib:$RUBYLIB"
            fi
          '';
        };
      }
    );
}
