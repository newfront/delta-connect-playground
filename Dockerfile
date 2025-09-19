FROM deltaio/delta-docker:4.0.0

ARG NBuser=NBuser
ARG GROUP=NBuser
ARG GRPCIO_VERSION=1.74.0
ARG WORKDIR=/opt/spark/work-dir
ARG DELTA_LAKE_VERSION=4.0.0

# OS Installations Configurations
# note: you can modify the base Dockerfile from delta-io/delta-docker
# or: switch to the USER root, but make sure you switch back to "NBuser" after applying commands that need
# root user permissions

# User root
# do things that the root user needs
# ...
# now switch back to NBuser
USER ${NBuser}
RUN pip install --quiet --no-cache-dir grpcio==${GRPCIO_VERSION} grpcio-status==${GRPCIO_VERSION} delta-spark==${DELTA_LAKE_VERSION}

# Configure Ownership
COPY --chown=${NBuser} scripts/entrypoint.sh "${WORKDIR}"
COPY --chown=${NBuser} scripts/startup.sh "${WORKDIR}"

# for spark-connect-server
EXPOSE 15002
# for the spark-connect-server ui
EXPOSE 4040

# for JupyterLab
EXPOSE 8888-8889
# for spark-connect-client (driver)
# run from JupyterLab
EXPOSE 4041

ENTRYPOINT ["bash", "entrypoint.sh"]
