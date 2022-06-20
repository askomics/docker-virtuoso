# docker-virtuoso

![Docker Build](https://img.shields.io/docker/pulls/askomics/virtuoso.svg)
[![Build Status](https://travis-ci.org/askomics/docker-virtuoso.svg?branch=master)](https://travis-ci.org/askomics/docker-virtuoso)


Virtuoso dockerized, based on Alpine

Based on [tenforce/docker-virtuoso](https://github.com/tenforce/docker-virtuoso) and [jplu/docker-virtuoso](https://github.com/jplu/docker-virtuoso).

Image have the same functionalities than [tenforce/docker-virtuoso](https://github.com/tenforce/docker-virtuoso), but it is lighter (123MB instead of 496MB)

## Pull from DockerHub

```bash
docker pull askomics/virtuoso
```

## Or build

```bash
# Clone the repo
git clone https://github.com/askomics/docker-virtuoso.git
cd docker-virtuoso
# Build image
docker build -t virtuoso .
```


## RUN

```bash
docker run --name my-virtuoso \
    -p 8890:8890 -p 1111:1111 \
    -e DBA_PASSWORD=myDbaPassword \
    -e SPARQL_UPDATE=true \
    -e DEFAULT_GRAPH=http://www.example.com/my-graph \
    -v /my/path/to/the/virtuoso/db:/data \
    -d askomics/virtuoso
```

## Configuration


### dba password
The `dba` password can be set at container start up via the `DBA_PASSWORD` environment variable. If not set, the default `dba` password will be used.

### SPARQL update permission
The `SPARQL_UPDATE` permission on the SPARQL endpoint can be granted by setting the `SPARQL_UPDATE` environment variable to `true`.

### .ini configuration
All properties defined in `virtuoso.ini` can be configured via the environment variables. The environment variable should be prefixed with `VIRT_` and have a format like `VIRT_$SECTION_$KEY`. `$SECTION` and `$KEY` are case sensitive. They should be CamelCased as in `virtuoso.ini`. E.g. property `ErrorLogFile` in the `Database` section should be configured as `VIRT_Database_ErrorLogFile=error.log`.

`virtuoso.ini` file will be recreated at each docker run.

### S3 connector
You can use a S3 bucket to load RDF files on startup. To do so, the S3 bucket
is mounted as a volume in the file system and loaded the same way the `toLoad`
folder is.  To configure the S3 bucket connection you need to define
environment variables when launch.

```bash
docker run --name my-virtuoso \
    -p 8890:8890 -p 1111:1111 \
    -e DBA_PASSWORD=myDbaPassword \
    -e SPARQL_UPDATE=true \
    -e DEFAULT_GRAPH=http://www.example.com/my-graph \
    -e S3_SERVER_URL=http://s3server.dns:9000 \
    -e S3_ACCESS_KEY_ID=the_s3_access_key \
    -e S3_SECRET_ACCESS_KEY=ths_s3_secret \
    -e S3_BUCKET_NAME=myBucket \
    -d askomics/virtuoso
```
The S3 bucket is mounted on `/tmp/toLoadS3` folder.  After the RDF files have
been imported, then the S3 folder is unmounted.  You can import RDF data from
the S3 folder and the `toLoad` folder. Both are not exclusives.

## Dumping your Virtuoso data as quads
Enter the Virtuoso docker, open ISQL and execute the `dump_nquads` procedure. The dump will be available in `/my/path/to/the/virtuoso/db/dumps`.

```bash
docker exec -it my-virtuoso sh
isql-v -U dba -P $DBA_PASSWORD
SQL> dump_nquads ('dumps', 1, 10000000, 1);
```

For more information, see http://virtuoso.openlinksw.com/dataspace/doc/dav/wiki/Main/VirtRDFDumpNQuad

## Loading quads in Virtuoso
### Manually
Make the quad `.nq` files available in `/my/path/to/the/virtuoso/db/dumps`. The quad files might be compressed. Enter the Virtuoso docker, open ISQL, register and run the load.

```bash
docker exec -it my-virtuoso sh
isql-v -U dba -P $DBA_PASSWORD
SQL> ld_dir('dumps', '*.nq', 'http://foo.bar');
SQL> rdf_loader_run();
```

Validate the `ll_state` of the load. If `ll_state` is 2, the load completed.

```sql
select * from DB.DBA.load_list;
```

For more information, see http://virtuoso.openlinksw.com/dataspace/doc/dav/wiki/Main/VirtBulkRDFLoader

### Automatically
By default, any data that is put in the `toLoad` directory in the Virtuoso database folder (`/my/path/to/the/virtuoso/db/toLoad`) is automatically loaded into Virtuoso on the first startup of the Docker container. The default graph is set by the DEFAULT_GRAPH environment variable, which defaults to `http://localhost:8890/DAV`.

## Creating a backup
A virtuoso backup can be created by executing the appropriate commands via the ISQL interface.

```bash
docker exec -i my-virtuoso mkdir -p backups
docker exec -i my-virtuoso isql-v <<EOF
    exec('checkpoint');
    backup_context_clear();
    backup_online('backup_',30000,0,vector('backups'));
    exit;
```
## Restoring a backup
To restore a backup, stop the running container and restore the database using a new container.

```bash
docker run --rm  -it -v path-to-your-database:/data askomics/virtuoso virtuoso-t +restore-backup backups/backup_ +configfile /data/virtuoso.ini
```

The new container will exit once the backup has been restored, you can then restart the original db container.

It is also possible to restore a backup placed in /data/backups using a environment variable. Using this approach the backup is loaded automatically on startup and it is not required to run a separate container.

```bash
docker run --name my-virtuoso \
            -p 8890:8890 \
            -p 1111:1111 \
            -e DBA_PASSWORD=dba \
            -e SPARQL_UPDATE=true \
            -e BACKUP_PREFIX=backup_ \_
            -v path-to-your-database:/data \
            -d askomics/virtuoso
```
