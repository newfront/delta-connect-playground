#!/usr/bin/env bash
set -Eeuo pipefail

export PYSPARK_DRIVER_PYTHON=jupyter
export PYSPARK_DRIVER_PYTHON_OPTS='lab --ip=0.0.0.0'
export DELTA_SPARK_VERSION='4.0.0'
export DELTA_PACKAGE_VERSION=delta-spark_2.13:${DELTA_SPARK_VERSION}

# todo Add a flag to "start the server"
# todo otherwise, we are running as the "client"
# todo this can help with the SPARK_CONNECT_MODE as server or client
CONNECT_LOG=/opt/spark/logs/connect-server.log
CONNECT_PORT=15002
CONNECT_SCRIPT=/opt/spark/work-dir/scripts/start-connect-server.sh

echo "Starting up the Spark gRPC Server: Port: ${CONNECT_PORT} will be exposed to localhost or within the docker network"

# Ensure executable and start in background with logging
chmod +x "${CONNECT_SCRIPT}" || true
nohup "${CONNECT_SCRIPT}" > "${CONNECT_LOG}" 2>&1 &
CONNECT_PID=$!

# Ensure background process is cleaned up on exit
cleanup() {
  if kill -0 "${CONNECT_PID}" 2>/dev/null; then
    echo "Stopping Spark Connect server (pid=${CONNECT_PID})..."
    kill "${CONNECT_PID}" 2>/dev/null || true
    wait "${CONNECT_PID}" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

# Wait for port to be ready (up to 60s)
echo "Waiting for Spark Connect server to become ready on port ${CONNECT_PORT}..."
#for i in {1..60}; do
#  if (exec 3<>/dev/tcp/127.0.0.1/${CONNECT_PORT}) 2>/dev/null; then
#    exec 3>&- 3<&-
#    echo "Spark Connect server is ready."
#    break
#  fi
#  sleep 1
#  if ! kill -0 "${CONNECT_PID}" 2>/dev/null; then
#    echo "Spark Connect server exited unexpectedly. See ${CONNECT_LOG}"
#    cat ${CONNECT_LOG}
#    exit 1
#  fi
#  if [[ $i -eq 60 ]]; then
#    echo "Timed out waiting for Spark Connect server. See ${CONNECT_LOG}"
#    exit 1
#  fi
#done

echo "SparkSession:initalizing: cores:${PYSPARK_TOTAL_CORES}, memory:${PYSPARK_DRIVER_MEMORY}"

# Run PySpark/Jupyter in the foreground to keep the container alive
"$SPARK_HOME/bin/pyspark" \
  --packages io.delta:${DELTA_PACKAGE_VERSION},io.delta:delta-connect-client_2.13:4.0.0,org.apache.spark:spark-protobuf_2.13:4.0.0 \
  --driver-memory "${PYSPARK_DRIVER_MEMORY}" \
  --driver-cores "${PYSPARK_TOTAL_CORES}" \
  --conf "spark.sql.warehouse.dir=/opt/spark/work-dir/hitchhikers_guide/warehouse" \
  --conf "spark.driver.extraJavaOptions=-Divy.cache.dir=/tmp -Divy.home=/tmp -Dio.netty.tryReflectionSetAccessible=true" \
  --conf "spark.executor.extraJavaOptions=-Dio.netty.tryReflectionSetAccessible=true" \
  --conf "spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension" \
  --conf "spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog" \
  --conf "spark.connect.extensions.relation.classes=org.apache.spark.sql.connect.delta.DeltaRelationPlugin" \
  --conf "spark.connect.extensions.command.classes=org.apache.spark.sql.connect.delta.DeltaCommandPlugin"
