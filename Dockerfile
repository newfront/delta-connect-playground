FROM newfrontdocker/delta-docker:4.0.0
ARG NBuser=NBuser
ARG GRPCIO_VERSION=1.74.0

USER ${NBuser}
RUN pip install --quiet --no-cache-dir grpcio==${GRPCIO_VERSION} grpcio-status==${GRPCIO_VERSION}

ENTRYPOINT ["bash", "startup.sh"]
