{
  description = "Ruby on Rails development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        ruby = pkgs.ruby_3_4;
      in
      {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            pkg-config
          ];

          buildInputs = with pkgs; [
            ruby
            nodejs
            libyaml
            openssl
            imagemagick
            kubernetes-helm

            # Rust toolchain for the ext/async_matrix_e2ee vodozemac binding (magnus + rb_sys).
            rustc
            cargo
            # rb_sys/magnus generate Ruby bindings with bindgen, which needs libclang.
            clang
            libclang
          ];

          shellHook = ''
            export GEM_HOME="$HOME/.gem-${ruby.version}"
            export GEM_PATH="$GEM_HOME"
            export PATH="$GEM_HOME/bin:$PATH"
            export BUNDLE_GEMFILE="$PWD/Gemfile"
            export BUNDLE_PATH="$GEM_HOME"
            export BUNDLE_BIN="$GEM_HOME/bin"

            # rb_sys bindgen needs to locate libclang at build time.
            export LIBCLANG_PATH="${pkgs.libclang.lib}/lib"
          '';
        };
      }
    );
}
