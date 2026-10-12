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

        # tree_sitter_language_pack (via tree_haver, via ast-crispr-ruby-prism) builds its
        # extension with cargo, which a gem derivation does not have. Its precompiled gems
        # need no compiler, but bundix writes one entry with no platform, so the gem it names
        # and the hash it records come from different files. The platform belongs to the
        # system being built for rather than to the lockfile, so it is chosen here.
        treeSitterPlatforms = {
          x86_64-linux = {
            platform = "x86_64-linux";
            sha256 = "0zkcp53qg4jdlym362chd0ri5j1hzrrb1fbm7d10f24sdq3kxklq";
          };
          aarch64-linux = {
            platform = "aarch64-linux";
            sha256 = "0v5300q2hnkc1f7ci2wyr9i19xdznrd0r3mkc0zraak8p7dljigr";
          };
          x86_64-darwin = {
            platform = "x86_64-darwin";
            sha256 = "0x5gv12hm54pp54wf3g3fisc0mlp63ryhcwd72ra1fnq0s1cmnp4";
          };
          aarch64-darwin = {
            platform = "arm64-darwin";
            sha256 = "0xaw6wsf1qz1i4ppjhp2qk4zbdaf1k4g5k6w2k5pww044d2c6ajc";
          };
        };

        gemset = import ./gemset.nix;

        treeSitterGem =
          let
            selected = treeSitterPlatforms.${system} or (throw
              "tree_sitter_language_pack has no precompiled gem for ${system}");
            generic = gemset.tree_sitter_language_pack;
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
          gemset = gemset // { tree_sitter_language_pack = treeSitterGem; };
          extraConfigPaths = [ "${gemspecFiles}/." ];
        };

      in
      {
        devShells.default = lib.mkRubyShell {
          buildInputs = with pkgs; [
            gems
            gems.wrappedRuby

            # license-eye, which reads .licenserc.yaml: `license-eye header check` verifies the notice every Ruby file opens with. It is Go rather than Ruby, so it comes from here rather than from the bundle.
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
