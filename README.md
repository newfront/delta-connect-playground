# delta-connect-playground
This playground is a simple example of how to use the Delta Lake gRPC server to write to a Delta Lake table.

## Building the Docker Image
We need to build an image with the additional python dependencies required
for PySpark to connect to the gRPC server.

~~~bash
docker build -t newfrontdocker/delta-connect-playground:latest .
~~~

~~~bash
docker run -it \
  -p 8888-8889:8888-8889 \
  newfrontdocker/delta-connect-playground:latest
~~~

## What is the Connect Server?
> Note: The scripts directory starts the `delta-connect` server when you start up the Docker image. This will pull down the `spark.connect` extension jars before spinning up the server.

The command will install the Spark extensions to enable the gRPC server we'll use to write to our Delta Lake tables.
```text
${SPARK_HOME}/sbin/start-connect-server.sh \
  --conf "spark.driver.extraJavaOptions=-Divy.cache.dir=/tmp -Divy.home=/tmp -Dio.netty.tryReflectionSetAccessible=true" \
  --packages io.delta:delta-connect-server_2.13:4.0.0,com.google.protobuf:protobuf-java:3.25.1 \
  --conf "spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension" \
  --conf "spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog" \
  --conf "spark.connect.extensions.relation.classes=org.apache.spark.sql.connect.delta.DeltaRelationPlugin" \
  --conf "spark.connect.extensions.command.classes=org.apache.spark.sql.connect.delta.DeltaCommandPlugin"
```

**Server Port**: 15002 - need to punch a hole in the firewall to allow peering on this port via the connect client application.

## Notes: 
* [Spark Connect](https://spark.apache.org/docs/latest/spark-connect-overview.html) - docs on Spark Connect
* [Delta Lake](https://delta.io/) - main Delta Lake docs
* Delta Connect Server: https://mvnrepository.com/artifact/io.delta/delta-connect-server_2.13/4.0.0
* Delta Connect Client: https://mvnrepository.com/artifact/io.delta/delta-connect-client_2.13/4.0.0