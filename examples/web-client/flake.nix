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

        gemsetAttrs = import ./gemset.nix;

        vodozemacGem =
          let
            selected = vodozemacPlatforms.${system} or (throw
              "vodozemac has no precompiled gem for ${system}");
            generic = gemsetAttrs.vodozemac;
          in
          generic // {
            version = "${generic.version}-${selected.platform}";
            source = generic.source // { sha256 = selected.sha256; };
          };

        gemset = gemsetAttrs // { vodozemac = vodozemacGem; };

        gems = pkgs.bundlerEnv {
          name = "async-matrix-example";
          ruby = pkgs.ruby_3_4;
          gemfile = ./Gemfile;
          lockfile = ./Gemfile.lock;
          inherit gemset;
        };

        pnpmDeps = pkgs.fetchPnpmDeps {
          pname = "async-matrix-example";
          version = "0";
          src = ./.;
          fetcherVersion = 4;
          hash = "sha256-vEjrgFOWWNsqm0PwGJHljWEJsbcdB2ABz3BFtqHrH7w=";
        };

      in
      {
        devShells.default = lib.mkRubyViteShell {
          inherit pnpmDeps;

          buildInputs = with pkgs; [
            gems
            gems.wrappedRuby
          ];

          shellHook = /* bash */ ''
            export BUNDLE_FORCE_RUBY_PLATFORM=false
            export BUNDLE_GEMFILE="$PWD/Gemfile"
            export BUNDLE_FROZEN=false
          '';

        };
      }));
}
