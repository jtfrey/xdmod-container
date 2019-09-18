# xdmod-container

This repository includes container provisioning files to create a container that executes the XDMoD web application.  Both the MariaDB server and Apache httpd execute within the container, making the service completely self-contained.

The MariaDB instance will retain the default CentOS 7 configuration; no `root` password is set, the test database is not removed, and the anonymous user is not removed.  Since all access is internal to the container, there's no need to secure it.

The container features a runloop that waits for files to appear in `/var/lib/XDMoD-ingest-queue/in`.  The file(s) are ingested into the database and will be moved to `/var/lib/XDMoD-ingest-queue/out` if successful or to `/var/lib/XDMoD-ingest-queue/error` if not.  Results of the operations are logged to `/var/log/xdmod/ingest-queue.log`.

## Docker

The Docker container should be spawned with TCP port 8080 mapped to a host port to expose the web application.  The database starts out uninitialized; when a container instance is spawned an external directory may be bind-mounted at `/var/lib/mysql` in the container to make the database persistent across restarts of the instance, and when the container entrypoint script is first executed the database setup will be completed automatically.

An external directory can also be bind-mounted at `/var/lib/XDMoD-ingest-queue`.  The directory must have the following subdirectories:

  - `in`
  - `out`
  - `error`

These three directories will be created automatically by the entrypoint script if not present in `/var/lib/XDMoD-ingest-queue`.  Using an external directory allows processes outside the container to copy Slurm accounting log files to the `in` subdirectory and the entrypoint runloop will awake within 5 minutes and ingest the data.

### Example

The container image is built in this repository directory using:

```
$ ROOT_PASSWORD="<password>" docker build --rm --tag local/xdmod:8.1.2
```

The following example illustrates the creation of an instance with persistent database and ingest queue directories:

```
$ mkdir -p /tmp/XDMoD-Caviness/ingest-queue
$ mkdir -p /tmp/XDMoD-Caviness/database
$ docker run --detach --restart unless-stopped \
    --name XDMoD-Caviness \
    --volume "/tmp/XDMoD-Caviness/database:/var/lib/mysql:rw" \
    --volume "/tmp/XDMoD-Caviness/ingest-queue:/var/lib/XDMoD-ingest-queue:rw" \
    --publish 8080:8080
    local/xdmod:8.1.2
```

Once the instance is online, XDMoD must be initialized and the ingest queue activated:

```
$ docker exec -it XDMoD-Caviness /bin/bash -l
[container]> xdmod-setup
    :
[container]> touch /var/lib/XDMoD-ingest-queue/enable
[container]> exit
```

At this point, copying files to `/tmp/XDMoD-Caviness/ingest-queue/in` will see them processed in the runloop.  Point a web browser to http://localhost:8080/ to use the web application.

## Singularity

Singularity 3.0 or newer is required (3.2.1 was used in our production environment) for the network port mapping and support for instances (service-like containers).

Rather than bind-mounting directories at specific paths as outline above for Docker, with Singularity a writable overlay file system is a good option.  Any changes to the file system relative to the read-only container image are written to an external directory.  As with Docker, port 8080 is mapped to a host port to expose the web application.

### Example

The container image is built in this repository directory using:

```
$ ROOT_PASSWORD="<password>" singularity build XDMoD-8.1.2.sif Singularity
```

The following example illustrates the execution of an instance with an overlay file system:

```
$ mkdir -p /tmp/XDMoD-Caviness
$ singularity instance start --overlay /tmp/XDMoD-Caviness --net --dns 10.65.0.13 \
    --network bridge --network-args "portmap=8080:8080/tcp" \
    XDMoD-8.1.2.sif XDMoD-Caviness
```

Once the instance is online, XDMoD must be initialized and the ingest queue activated:

```
$ singularity shell instance://XDMoD-Caviness
[container]> xdmod-setup
    :
[container]> touch /var/lib/XDMoD-ingest-queue/in
[container]> touch /var/lib/XDMoD-ingest-queue/enable
[container]> exit
```

At this point, copying files to `/tmp/XDMoD-Caviness/upper/var/lib/XDMoD-ingest-queue/in` will see them processed in the runloop.  Point a web browser to http://localhost:8080/ to use the web application.

## Helper Scripts

The `sbin` directory includes a SysV-style script that can be used to start, stop, restart, and query status of instances of the Singularity container.

To start a new or existing instance with the default container image and overlay directory:

```
$ sbin/instance Caviness start
```

To use a different container image and overlay directory:

```
$ sbin/instance --overlay=/tmp/XDMoD --image=./XDMoD-uge.sif Farber start
```

The `status` action returns 0 if the instance is running, non-zero otherwise:

```
$ sbin/instance Farber status
```

The `--verbose` option increases the amount of output displayed by the command, and the `--help` option summarizes the command and all options.

