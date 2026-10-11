{
  description = "Synapse images, one per Matrix specification version";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";

    # v1.13 and later are only on develop, and no image is published for it, so it is fetched and
    # built from source with the docker/Dockerfile it ships with. Pinned by flake.lock.
    synapse-develop = { url = "github:element-hq/synapse/develop"; flake = false; };

    # The identity server, which is a server of its own rather than a Synapse: it holds which
    # address belongs to which user. No image is published for it, so it is built from the source
    # with the Dockerfile it ships with, as the develop Synapses are. Pinned by flake.lock.
    sydent = { url = "github:element-hq/sydent"; flake = false; };

    # The push gateway, which delivers a notification to an application. No image is published for
    # it either, so it is built from the source with the Dockerfile it ships with.
    sygnal = { url = "github:element-hq/sygnal"; flake = false; };
  };

  outputs = { self, nixpkgs, utils, ... }@inputs:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Where the images are published. The workflow sets this from the repository owner.
        #
        # The tag names the specification version, not the Synapse version: synapse:spec-v1.11 is
        # "the Synapse which implements Matrix v1.11", which is what a caller wants to ask for.
        repository = "ghcr.io/n-at-han-k/synapse";

        # Matrix specification version -> the Synapse which first advertises it.
        #
        # The revision was found from the history of the file which holds the advertised list
        # (synapse/rest/client/versions.py, now rust/src/handlers/versions.rs): the first commit to
        # add each "v1.N", and the earliest release tag containing it.
        #
        # A released version uses the image upstream published at the time, rather than rebuilding
        # that revision's Dockerfile. Those Dockerfiles no longer build: v1.54.0's installs
        # libwebp6 from Debian Bullseye, which today's apt cannot resolve, and it fails with exit
        # 100. Upstream's image is both the artifact it was meant to produce and the one that was
        # actually tested, so it is what we republish.
        #
        # Only ghcr.io/element-hq/synapse from v1.98.0 onwards, so docker.io/matrixdotorg/synapse
        # is used throughout - it carries every tag we need.
        versions = {
          "v1.1" = { published = "v1.54.0"; };
          "v1.2" = { published = "v1.54.0"; };
          # Synapse never advertised v1.3 on its own: every release up to 1.69.0 advertised as far as
          # v1.2, and 1.70.0 jumped straight to v1.1 through v1.4. 1.70.0 and 1.71.0 are still too
          # early, because the refresh endpoint v1.3 defines is served at
          # /_matrix/client/v1/refresh there, where the specification puts it under v3: 1.72.0 is
          # the first release whose RefreshTokenServlet takes client_patterns("/refresh$"). So both
          # versions take it, being the earliest release which advertises them and serves what they
          # define.
          #
          # The servlet is registered only where `refreshable_access_token_lifetime` is set, which
          # reads as something the rig would have to turn on - but it defaults to "5m" rather than
          # to nothing, so homeserver.yaml needs no setting for it.
          "v1.3" = { published = "v1.72.0"; };
          "v1.4" = { published = "v1.72.0"; };
          "v1.5" = { published = "v1.74.0"; };
          "v1.6" = { published = "v1.84.0"; };

          # Synapse never advertised v1.7 on its own, as it never did v1.3: 1.97.0 advertises as far
          # as v1.6, and 1.98.0 jumps straight to v1.7 through v1.9. 1.84.0 would not do either way,
          # since it serves neither operation v1.7 adds - the login token was behind msc3882_enabled
          # at /org.matrix.msc3882/login/token until 1.88.0 stabilised it at /login/get_token, and
          # the media URI a client reserves before the bytes are ready arrived with
          # rest/media/create_resource.py in 1.97.0. So v1.7 takes 1.98.0 with v1.8 and v1.9.
          "v1.7" = { published = "v1.98.0"; };
          "v1.8" = { published = "v1.98.0"; };
          "v1.9" = { published = "v1.98.0"; };
          "v1.10" = { published = "v1.107.0"; };
          "v1.11" = { published = "v1.111.0"; };
          "v1.12" = { published = "v1.135.0"; };

          # Nothing advertises v1.18 or v1.19 yet - develop reaches v1.17 - so those build the
          # newest Synapse there is. bin/test reports a server which does not advertise the version
          # under test rather than passing silently.
          "v1.13" = { source = inputs.synapse-develop; };
          "v1.14" = { source = inputs.synapse-develop; };
          "v1.15" = { source = inputs.synapse-develop; };
          "v1.16" = { source = inputs.synapse-develop; };
          "v1.17" = { source = inputs.synapse-develop; };
          "v1.18" = { source = inputs.synapse-develop; };
          "v1.19" = { source = inputs.synapse-develop; };
        };

        upstream = "docker.io/matrixdotorg/synapse";

        # Obtain the base image: either the one upstream published, or one built from the source
        # upstream tagged, using its own Dockerfile and its whole tree as the build context.
        base = specification: version:
          if version ? published then ''
            base="${upstream}:${version.published}"

            echo "Matrix ${specification}: pulling $base" >&2
            docker pull "$base"
          '' else ''
            base="synapse-source:spec-${specification}"

            echo "Matrix ${specification}: building $base from ${version.source}" >&2
            docker build \
              --file ${version.source}/docker/Dockerfile \
              --build-arg SYNAPSE_VERSION_STRING=develop \
              --tag "$base" \
              ${version.source}
          '';

        build = specification: version:
          pkgs.writeShellApplication {
            name = "synapse-${specification}";

            runtimeInputs = [ pkgs.docker ];

            text = ''
              repository="''${IMAGE_REPOSITORY:-${repository}}"
              tag="$repository:spec-${specification}"

              ${base specification version}

              # The image leaves /data owned by root, and start.py drops privileges before Synapse
              # opens its database. The rig mounts only the configuration, so with nothing at /data
              # Synapse cannot write. One layer on top fixes that, and keeps the compose file from
              # having to care.
              printf 'FROM %s\nRUN mkdir -p /data && chmod 777 /data\n' "$base" \
                | docker build --tag "$tag" -

              if [ -n "''${PUSH:-}" ]; then
                echo "Matrix ${specification}: pushing $tag" >&2
                docker push "$tag"
              fi

              echo "$tag"
            '';
          };

        # The identity server. One image rather than one per version: the identity API has not
        # changed across the versions this rig covers - every operation it defines is in all of
        # them - so there is nothing to vary.
        sydent = pkgs.writeShellApplication {
          name = "sydent";

          runtimeInputs = [ pkgs.docker ];

          text = ''
            repository="''${IMAGE_REPOSITORY:-ghcr.io/n-at-han-k/sydent}"
            tag="$repository:latest"

            echo "Sydent: building from ${inputs.sydent}" >&2
            docker build --file ${inputs.sydent}/Dockerfile --tag sydent-source:latest ${inputs.sydent}

            # Sydent writes its configuration and its database into /data, which its image leaves
            # owned by root while the entrypoint runs as the sydent user. The rig mounts only the
            # configuration, so without this there is nowhere for the database to go.
            printf 'FROM %s\nUSER root\nRUN mkdir -p /data && chmod 777 /data\nUSER sydent\n' sydent-source:latest \
              | docker build --tag "$tag" -

            if [ -n "''${PUSH:-}" ]; then
              echo "Sydent: pushing $tag" >&2
              docker push "$tag"
            fi

            echo "$tag"
          '';
        };
        # The push gateway. One image, for the same reason as the identity server: the push gateway
        # API has one operation and it is in every version this rig covers.
        sygnal = pkgs.writeShellApplication {
          name = "sygnal";

          runtimeInputs = [ pkgs.docker ];

          text = ''
            repository="''${IMAGE_REPOSITORY:-ghcr.io/n-at-han-k/sygnal}"
            tag="$repository:latest"

            echo "Sygnal: building from ${inputs.sygnal}" >&2
            docker build --file ${inputs.sygnal}/docker/Dockerfile --tag "$tag" ${inputs.sygnal}

            if [ -n "''${PUSH:-}" ]; then
              echo "Sygnal: pushing $tag" >&2
              docker push "$tag"
            fi

            echo "$tag"
          '';
        };
      in
      {
        packages = builtins.mapAttrs build versions // { inherit sydent sygnal; };

        apps = builtins.mapAttrs
          (specification: package: utils.lib.mkApp { drv = package; })
          self.packages.${system};
      });
}
