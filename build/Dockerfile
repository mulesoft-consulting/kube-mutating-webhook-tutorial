FROM alpine:latest

# set environment variables
ENV SIDECAR_INJECTOR=/usr/local/bin/sidecar-injector \
  USER_UID=1001 \
  USER_NAME=sidecar-injector

# install sidecar-injector binary
COPY build/_output/linux/bin/sidecar-injector ${SIDECAR_INJECTOR}

# copy licenses
RUN mkdir /licenses
COPY LICENSE /licenses

# set entrypoint
ENTRYPOINT ["/usr/local/bin/sidecar-injector"]

# switch to non-root user
USER ${USER_UID}
