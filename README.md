# delta-connect-playground
This playground is a simple example of how to use the Delta Lake gRPC server to write to a Delta Lake table.

## Building the Docker Image
We need to build an image with the additional Python dependencies required for PySpark to connect to the gRPC server. The image extends the Delta Docker base image. 

Take a peek at the [entrypoint.sh](./scripts/entrypoint.sh) file to see how the container runs. There are two available modes: `server` and `client`. These options are passed from the docker-compose.yaml via `command: ["server"]` or `command: ["client"]`. 

~~~bash
docker build \
  -t newfrontdocker/delta-connect-playground:latest .
~~~

> The image doesn't need to be built if you want to use what is in Docker Hub: [newfrontdocker/delta-connect-playground:4.0.0](https://hub.docker.com/r/newfrontdocker/delta-connect-playground/tags)

## Creating the Docker Network
~~~
docker network create connect
~~~

### Manually Run the Server
> Note: The `docker-compose.yaml` will start both the server and client automatically. If you want to run just the server then you can use the following command.
```bash
docker compose up --remove-orphans delta-connect-server
```

## Run the Delta Connect Server
This is where the magic happens. Once the server is up and running, you can connect to it via the spark-connect protocol. 

~~~bash
docker compose up --remove-orphans delta-connect-server
~~~

You will see a lot of logging followed by this line:

```text
INFO SparkConnectServer: Spark Connect server started at: 0:0:0:0:0:0:0:0:15002
```

Once the server is started, any interaction you have will be visible via the logs in the container.

**View the Server UI**: http://localhost:4040/connect/

## Connect to the Delta Connect Server

### Manually Run the Client
> Note: The `docker-compose.yaml` will start both the server and client automatically. If you want to run just the client then you can use the following command.

```bash
docker compose up --remove-orphans delta-connect-playground 
```
> Note: the client is pretty useless without the server running :)

Here is an example of connecting outside of Jupyter from within the Docker network
```bash
$SPARK_HOME/bin/pyspark --remote "sc:docker-connect-server"
```

Here is an example of connecting from localhost.
> Note: the docker-compose.yaml file exposes port 15002 on the host.
```bash
$SPARK_HOME/bin/pyspark --remote "sc:localhost"
```

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

**Server Port**: **15002** - we have to punch a hole in the Docker network to allow peering on this port via the connect client application. This is done via the `docker-compose.yaml` file.

> Tip: To see if you can connect to the remote server:
```text
% nc -z localhost 15002
Connection to localhost port 15002 [tcp/*] succeeded!
```

## Notes: 
* [Spark Connect](https://spark.apache.org/docs/latest/spark-connect-overview.html) - docs on Spark Connect
* [Delta Lake](https://delta.io/) - main Delta Lake docs
* Delta Connect Server: https://mvnrepository.com/artifact/io.delta/delta-connect-server_2.13/4.0.0
* Delta Connect Client: https://mvnrepository.com/artifact/io.delta/delta-connect-client_2.13/4.0.0

## Release the base container
~~~
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t newfrontdocker/delta-connect-playground:4.0.0 \
  -f Dockerfile \
  .
~~~