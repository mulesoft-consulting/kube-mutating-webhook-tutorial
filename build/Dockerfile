FROM alpine:latest

# set environment variables
ENV SIDECAR_INJECTOR=/usr/local/bin/sidecar-injector \
  USER_UID=1001 \
  USER_NAME=sidecar-injector

# install sidecar-injector binary
COPY ./_output/sidecar-injector ${SIDECAR_INJECTOR}

# set entrypoint
ENTRYPOINT ["/usr/local/bin/sidecar-injector"]

# switch to non-root user
USER ${USER_UID}