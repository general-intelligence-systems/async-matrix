{
  description = "Ratalada Project";
  inputs = {
    nixpkgs.url = "nixpkgs"; # this machine\'s system nixpkgs, via the registry
    utils.url = "github:numtide/flake-utils";
    mine.url = "github:n-at-han-k/flake.nix";
    mine.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, nixpkgs, utils, mine }:
    (utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        lib = mine.lib.${system};

        asyncMatrixGems = {
          "x86_64-linux" = { platform = "x86_64-linux"; sha256 = "1fz3qad96gr73hwj8q8mrcn0lxgl5lnfy7xqxklv8acqk5pjb5mm"; };
          "aarch64-linux" = { platform = "aarch64-linux"; sha256 = "0h48m7ki01i8ki3898rriy5bzifqf7j2gr424kwwqrc18k34zism"; };
          "x86_64-darwin" = { platform = "x86_64-darwin"; sha256 = "1zv4knrglbpblgz5pqngi3fj7l2agdskj0023pffdpxl0fvrp6bs"; };
          "aarch64-darwin" = { platform = "arm64-darwin"; sha256 = "1awm77al95gmm7isghv13qc1mfnih6jka2y98g4l9d38jbmlqrva"; };
        };

        asyncMatrixGem = asyncMatrixGems.${system} or null;

        gemsetAttrs = import ./gemset.nix;

        gemset =
          if asyncMatrixGem == null then
            gemsetAttrs
          else
            gemsetAttrs // {
              async-matrix = gemsetAttrs.async-matrix // {
                platform = asyncMatrixGem.platform;
                source = gemsetAttrs.async-matrix.source // {
                  sha256 = asyncMatrixGem.sha256;
                };
              };
            };

        gems = pkgs.bundlerEnv {
          name = "async-matrix";
          ruby = pkgs.ruby_3_4;
          gemfile = ./Gemfile;
          lockfile = ./Gemfile.lock;
          inherit gemset;
        };

        pnpmDeps = pkgs.fetchPnpmDeps {
          pname = "async-matrix";
          version = "0";
          src = ./.;
          fetcherVersion = 4;
          hash = "sha256-XoHhvkVtj/9m9TC5iAS+Wm3CKkKg6DHKChtvYdRNCS0=";
        };

      in
      {
        devShells.default = lib.mkRubyViteShell {
          inherit pnpmDeps;

          buildInputs = with pkgs; [
            gems
            gems.wrappedRuby
          ];
        };
      }));
}
