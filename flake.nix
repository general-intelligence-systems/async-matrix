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
        # bundix writes one entry with no platform, so the gem it names and the hash it records come
        # from different files: the name resolves to the source gem, which would want cargo, while
        # the hash is the platform gem's. The platform belongs to the system being built for rather
        # than to the lockfile, so it is chosen here.
        vodozemacPlatforms = {
          x86_64-linux = {
            platform = "x86_64-linux";
            sha256 = "04zhxk8kbsimh70yy5yssyyj3bq6267dv8c7j6gdl8f9jnhby7w4";
          };
          aarch64-linux = {
            platform = "aarch64-linux";
            sha256 = "1m28m8wh3wb00a95w7al8la8apkbqg1v52palw0czincgpabi0gi";
          };
          x86_64-darwin = {
            platform = "x86_64-darwin";
            sha256 = "0fggkv23lr2d0rkqz01736k8bja0nqh9gvvxagdlhcncyxk58sh3";
          };
          aarch64-darwin = {
            platform = "arm64-darwin";
            sha256 = "10rxr1zfjs0gdjghvgish8wjd3aa4k4bmhdvi6hd5sljz28dx23i";
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
          ruby = pkgs.ruby_4_0;
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
