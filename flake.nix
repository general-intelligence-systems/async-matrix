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

        # Same problem as brute: the Gemfile says `gemspec`, which makes bundler
        # look for a *.gemspec beside the gemfile it is reading. bundlerEnv
        # reads its own store copy, where that neighbour does not exist, so
        # resolution dies with "There are no gemspecs at /nix/store/...".
        # extraConfigPaths is cp -r'd into that same dir; the trailing /.
        # copies the contents rather than the hash-named directory itself.
        # version.rb comes along because async-matrix.gemspec
        # require_relative's it for Async::Matrix::VERSION.
        gemspecFiles = pkgs.runCommand "async-matrix-gemspec" { } ''
          mkdir -p $out/lib/async/matrix
          cp ${./async-matrix.gemspec}          $out/async-matrix.gemspec
          cp ${./lib/async/matrix/version.rb}   $out/lib/async/matrix/version.rb
        '';

        # Not lib.buildGemset: extraConfigPaths is needed for the gemspec
        # above, which buildGemset does not take.
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
            trufflehog
          ];

          shellHook = /* bash */ ''
            # This machine's wrapped ruby exports BUNDLE_GEMFILE pointing at a
            # read-only store dir, which makes `bundle lock` here fail with
            # "File system is read-only". Point bundler back at this project.
            export BUNDLE_GEMFILE="$PWD/Gemfile"
            export BUNDLE_FROZEN=false

            export LANG="''${LANG:-C.UTF-8}"
            export LC_ALL="''${LC_ALL:-$LANG}"

            # bundlerEnv resolves `gemspec` against its store copy, so
            # async-matrix itself is a path gem pointing there. Put the working
            # tree ahead of it: edits to lib/ take effect without re-evaluating
            # the flake.
            export RUBYLIB="$PWD/lib''${RUBYLIB:+:$RUBYLIB}"

            # async-rest is developed alongside this gem rather than consumed
            # from rubygems, so prefer a sibling checkout when one is present.
            if [ -d "$PWD/../async-rest/lib" ]; then
              export RUBYLIB="$PWD/../async-rest/lib:$RUBYLIB"
            fi
          '';
        };
      }
    );
}
