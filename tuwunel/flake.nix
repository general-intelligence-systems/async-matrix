{
  description = "Tuwunel images, one per Matrix specification version";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils, ... }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Where the images are published. The workflow sets this from the repository owner.
        #
        # The tag names the specification version, not the tuwunel version: tuwunel:spec-v1.11 is
        # "the tuwunel which implements Matrix v1.11", which is what a caller wants to ask for.
        repository = "ghcr.io/n-at-han-k/tuwunel";

        # Upstream publishes an image for every release, so nothing here is built from source: a
        # version resolves to a pull and a retag. Only ghcr.io/matrix-construct/tuwunel is read -
        # docker.io/jevolk/tuwunel carries the same tags, if that one is ever unreachable.
        upstream = "ghcr.io/matrix-construct/tuwunel";

        # The release every version is pinned to, below.
        release = "v1.9.4";

        # Matrix specification version -> the tuwunel which serves it.
        #
        # This is the same shape as synapse/flake.nix, and deliberately not the same mapping. That
        # one pins each specification version to the Synapse which first advertised it, because
        # Synapse adds versions in order as it implements them, so the first release to advertise
        # one is the oldest server the version can be tested against, and the build upstream
        # actually tested it on.
        #
        # Tuwunel does not work that way. Its advertised list records which versions it has done
        # the work for, in whatever order that happened: `/_matrix/client/versions` went from
        # {v1.1-v1.5, v1.11} in v1.0.0, to adding v1.10 in v1.4.7, v1.12 and v1.15 in v1.5.0,
        # v1.6-v1.9 and v1.13-v1.17 together in v1.7.1, and v1.18 and v1.19 in v1.8.2. So the
        # first release to advertise v1.5 is v1.0.0 - which predates most of tuwunel's development
        # and has no published image at all - and pinning there would test the client's v1.5 layer
        # against an old server rather than against that version of the specification.
        #
        # One tuwunel build advertises the whole range the rig covers, so every version is pinned
        # to the same release. The map is kept per version so that one of them can be held back,
        # or moved forward, on its own when a release regresses it.
        versions = {
          "v1.1" = { published = release; };
          "v1.2" = { published = release; };
          "v1.3" = { published = release; };
          "v1.4" = { published = release; };
          "v1.5" = { published = release; };
          "v1.6" = { published = release; };
          "v1.7" = { published = release; };
          "v1.8" = { published = release; };
          "v1.9" = { published = release; };
          "v1.10" = { published = release; };
          "v1.11" = { published = release; };
          "v1.12" = { published = release; };
          "v1.13" = { published = release; };
          "v1.14" = { published = release; };
          "v1.15" = { published = release; };
          "v1.16" = { published = release; };
          "v1.17" = { published = release; };
          "v1.18" = { published = release; };
          "v1.19" = { published = release; };
        };

        build = specification: version:
          pkgs.writeShellApplication {
            name = "tuwunel-${specification}";

            runtimeInputs = [ pkgs.docker ];

            text = ''
              repository="''${IMAGE_REPOSITORY:-${repository}}"
              tag="$repository:spec-${specification}"
              base="${upstream}:${version.published}"

              echo "Matrix ${specification}: pulling $base" >&2
              docker pull "$base"

              # Nothing is added on top. The image is distroless, runs as root and keeps its
              # database inside its own filesystem, so there is nothing for the rig to fix up - the
              # layer synapse/flake.nix adds exists only because Synapse's image leaves /data owned
              # by root and then drops privileges. Retagging republishes the bytes upstream
              # released, under the name the compose file asks for.
              docker tag "$base" "$tag"

              if [ -n "''${PUSH:-}" ]; then
                echo "Matrix ${specification}: pushing $tag" >&2
                docker push "$tag"
              fi

              echo "$tag"
            '';
          };
      in
      {
        packages = builtins.mapAttrs build versions;

        apps = builtins.mapAttrs
          (specification: package: utils.lib.mkApp { drv = package; })
          self.packages.${system};
      });
}
