{
  description = "async-matrix development environment";

  inputs.mine.url = "github:n-at-han-k/flake.nix";
  inputs.mine.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { mine, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        lib = mine.lib.${system};

        # Our Gemfile says `gemspec`, and async-matrix.gemspec opens
        # lib/async/matrix/version.rb for the version. bundlerEnv assembles a
        # store directory holding ONLY the Gemfile and the lockfile and points
        # BUNDLE_GEMFILE at it, so `gemspec` finds no .gemspec there and every
        # wrapped binary (bundle, rubocop, scampi) dies in Bundler.setup.
        #
        # extraConfigPaths is the escape hatch: those paths are copied in
        # alongside the Gemfile. Only version.rb is needed, not all of lib/ —
        # pulling lib/ in wholesale would rebuild the gem set on every source
        # edit (and drag in the compiled .so).
        gemspecVersion = pkgs.runCommand "async-matrix-gemspec-version" { } ''
          mkdir -p $out/lib/async/matrix
          cp ${./lib/async/matrix/version.rb} $out/lib/async/matrix/version.rb
        '';

        # mine.lib.buildGemset would be the one-liner here, but it has no way
        # to pass extraConfigPaths through to bundlerEnv.
        gems = pkgs.bundlerEnv {
          name = "async-matrix";
          ruby = pkgs.ruby_3_4;
          gemfile = ./Gemfile;
          lockfile = ./Gemfile.lock;
          gemset = ./gemset.nix;
          extraConfigPaths = [
            ./async-matrix.gemspec
            "${gemspecVersion}/lib"
          ];
        };
      in
      {
        # lib.mkRubyShell, not pkgs.mkShell: it brings bundix, pkg-config,
        # libyaml and openssl, and regenerates gemset.nix on entry, which is
        # what keeps the lockfile and the gem set from drifting after a bump.
        # Only buildGemset is unusable here (it cannot pass extraConfigPaths);
        # the shell builder is a separate helper and does not care.
        devShells.default = lib.mkRubyShell {
          buildInputs = with pkgs; [
            gems
            gems.wrappedRuby

            # scampi discovers co-located `__END__` specs with ripgrep.
            ripgrep

            rustc
            cargo
            clang
            libclang
          ];

          shellHook = ''
            export LIBCLANG_PATH="${pkgs.libclang.lib}/lib"

            # Point Bundler at the REAL Gemfile, unfrozen, so `bundle lock`
            # and `bundix -l` can relock after a version bump. bundlerEnv's
            # own wrappers (bundle, rubocop, scampi) set both of these
            # themselves and ignore what is exported here.
            export BUNDLE_GEMFILE="$PWD/Gemfile"
            export BUNDLE_FROZEN=false
          '';
        };
      }
    );
}
