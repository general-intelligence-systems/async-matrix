FROM ghcr.io/element-hq/synapse:latest

# The image leaves /data owned by root, and start.py drops privileges before
# synapse opens its database -- so with nothing mounted there, it cannot write.
# Only the config is mounted, which is why this has to be fixed in the image.
RUN mkdir -p /data && chmod 777 /data
