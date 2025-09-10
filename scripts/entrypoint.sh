#!/usr/bin/env bash

# echo commands to the terminal output
set -ex

# Check whether there is a passwd entry for the container UID
myuid=$(id -u)
mygid=$(id -g)
# turn off -e for getent because it will return error code in anonymous uid case
set +e
uidentry=$(getent passwd $myuid)
set -e

set -o posix

# Shell script for starting the Spark Connect server
if [ -z "${SPARK_HOME}" ]; then
  export SPARK_HOME="$(cd "`dirname "$0"`"/..; pwd)"
fi

export DELTA_SPARK_VERSION=4.0.0
export DELTA_CONNECT_SERVER_PORT=15002
export WORKDIR=/opt/spark/work-dir

case "$1" in
  server)
    shift 1

    # note: start-connect-server.sh calls sbin/spark-daemon.sh to background the process
    # given we want to run this process until it dies, then the container is the perfect
    # vehicle for that lifecycle...

    # keep the connect server in the foreground
    export SPARK_NO_DAEMONIZE=1

    CMD=(
      "$SPARK_HOME/sbin/start-connect-server.sh"
      --conf "spark.driver.extraJavaOptions=-Divy.cache.dir=/tmp -Divy.home=/tmp -Dio.netty.tryReflectionSetAccessible=true"
      --packages "io.delta:delta-connect-server_2.13:${DELTA_SPARK_VERSION},com.google.protobuf:protobuf-java:3.25.1"
      --conf "spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension"
      --conf "spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog"
      --conf "spark.connect.extensions.relation.classes=org.apache.spark.sql.connect.delta.DeltaRelationPlugin"
      --conf "spark.connect.extensions.command.classes=org.apache.spark.sql.connect.delta.DeltaCommandPlugin"
      "$@"
    )
    ;;
  client)
    shift 1
    export SPARK_CONNECT_MODE=1

    # check if SPARK_REMOTE is set
    # if not, use local docker network from docker-compose.yaml
    if [ -z "${SPARK_REMOTE}" ]; then
      export SPARK_REMOTE="sc://connect"
    fi

    #export PYSPARK_DRIVER_PYTHON=jupyter
    #export PYSPARK_DRIVER_PYTHON_OPTS='lab --ip=0.0.0.0'
    #export DELTA_SPARK_VERSION='4.0.0'
    #export DELTA_PACKAGE_VERSION=delta-spark_2.13:${DELTA_SPARK_VERSION}
    #CMD=(
    #  "$SPARK_HOME/bin/pyspark --packages io.delta:${DELTA_PACKAGE_VERSION},io.delta:delta-connect-client_2.13:${DELTA_SPARK_VERSION},com.google.protobuf:protobuf-java:3.25.1"
    #  --conf "spark.ui.port=4041"
    #  --conf "spark.driver.extraJavaOptions=-Divy.cache.dir=/tmp -Divy.home=/tmp -Dio.netty.tryReflectionSetAccessible=true"
    #  --conf "io.delta:delta-connect-client_2.13:${DELTA_SPARK_VERSION},com.google.protobuf:protobuf-java:3.25.1"
    #  --conf "spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension"
    #  --conf "spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog"
    #  "$@"
    #)
    CMD=(
      "$WORKDIR/startup.sh"
    )
    ;;

  *)
    echo "Use the commands: server or client for the entrypoint"
    CMD=("$@")
    ;;
esac

# Execute the container CMD under tini for better hygiene
exec /usr/bin/tini -s -- "${CMD[@]}"
# Need to keep the container alive.
# We can sit and check the pid ${SPARK_PID_DIR}
# stores: spark-{NBuser}-{org.apache.spark.sql.connect.service.SparkConnectServer-{instance_num}.pid
