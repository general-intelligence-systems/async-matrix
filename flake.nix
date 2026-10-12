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

        # vodozemac carries a Rust extension, and its precompiled platform gems need no compiler.
        # Gemfile.lock names every platform the gem ships, so bundix writes the one entry it always
        # writes: no platform, and the source gem's hash, which would want cargo to build.
        # The platform belongs to the system being built for rather than to the lockfile, so the
        # entry is rewritten here into the platform gem for this system.
        # These are the hashes for the version Gemfile.lock resolves: a bump needs them recomputed.
        vodozemacPlatforms = {
          x86_64-linux = {
            platform = "x86_64-linux";
            sha256 = "17sv2ccpbgxn7ymj6yf2kgc5z6f6j2rqfi4ivkxijzdkpsmksjzj";
          };
          aarch64-linux = {
            platform = "aarch64-linux";
            sha256 = "0c471xf3p8k6ylzi1jh2cfzfrwvr1bhf8pgfriavj9h9nrybyvd8";
          };
          x86_64-darwin = {
            platform = "x86_64-darwin";
            sha256 = "1kl0np4lkcngwpw3j87b0c7mp6krwq8cs4q20xsj60ckqbjvjcj7";
          };
          aarch64-darwin = {
            platform = "arm64-darwin";
            sha256 = "03qdp7dzmbpgmcds5w42vbd4n0hfqijync4bm8g6d7f9w3y639p1";
          };
        };

        gemset = import ./gemset.nix;

        vodozemacGem =
          let
            selected = vodozemacPlatforms.${system} or (throw
              "vodozemac has no precompiled gem for ${system}");
            generic = gemset.vodozemac;
          in
          generic // {
            version = "${generic.version}-${selected.platform}";
            source = generic.source // { sha256 = selected.sha256; };
          };

        gems = pkgs.bundlerEnv {
          name = "async-matrix-gems";
          ruby = pkgs.ruby_3_4;
          gemfile = ./Gemfile;
          lockfile = ./Gemfile.lock;
          gemset = gemset // { vodozemac = vodozemacGem; };
          extraConfigPaths = [ "${gemspecFiles}/." ];
        };

      in
      {
        devShells.default = lib.mkRubyShell {
          buildInputs = with pkgs; [
            gems
            gems.wrappedRuby

            skywalking-eyes
          ];

          shellHook = /* bash */ ''
            # bundlerEnv installs the platform gem vodozemac, so forcing the ruby platform asks
            # bundler for a gem which is not there.
            export BUNDLE_FORCE_RUBY_PLATFORM=false
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
