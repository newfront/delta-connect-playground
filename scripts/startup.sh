#!/usr/bin/env bash
set -ex

export SPARK_CONNECT_MODE=1
export PYSPARK_DRIVER_PYTHON=jupyter
export PYSPARK_DRIVER_PYTHON_OPTS='lab --ip=0.0.0.0'
export DELTA_SPARK_VERSION='4.0.0'
export DELTA_PACKAGE_VERSION=delta-spark_2.13:${DELTA_SPARK_VERSION}

echo "SparkSession:initalizing: cores:${PYSPARK_TOTAL_CORES}, memory:${PYSPARK_DRIVER_MEMORY}"

# Run PySpark/Jupyter in the foreground to keep the container alive
"$SPARK_HOME/bin/pyspark" \
  --packages io.delta:${DELTA_PACKAGE_VERSION},io.delta:delta-connect-client_2.13:4.0.0,org.apache.spark:spark-protobuf_2.13:4.0.0 \
  --driver-memory "${PYSPARK_DRIVER_MEMORY}" \
  --driver-cores "${PYSPARK_TOTAL_CORES}" \
  --conf "spark.ui.port=4041" \
  --conf "spark.sql.warehouse.dir=/opt/spark/work-dir/warehouse" \
  --conf "spark.driver.extraJavaOptions=-Divy.cache.dir=/tmp -Divy.home=/tmp -Dio.netty.tryReflectionSetAccessible=true" \
  --conf "spark.executor.extraJavaOptions=-Dio.netty.tryReflectionSetAccessible=true" \
  --conf "spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension" \
  --conf "spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog" \
  --conf "spark.connect.extensions.relation.classes=org.apache.spark.sql.connect.delta.DeltaRelationPlugin" \
  --conf "spark.connect.extensions.command.classes=org.apache.spark.sql.connect.delta.DeltaCommandPlugin"
