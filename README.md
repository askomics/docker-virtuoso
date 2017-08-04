# docker-virtuoso
Virtuoso dockerized, based on Alpine

The Dockerfile is based on the [tenforce/docker-virtuoso](https://github.com/tenforce/docker-virtuoso) and [jplu/docker-virtuoso](https://github.com/jplu/docker-virtuoso)

## Build

    # Clone the repo
    git clone https://github.com/xgaia/docker-virtuoso.git
    cd docker-virtuoso
    docker build -t virtuoso .

## RUN

    docker run --name my-virtuoso \
        -p 8890:8890 -p 1111:1111 \
        -e DBA_PASSWORD=myDbaPassword \
        -e SPARQL_UPDATE=true \
        -e DEFAULT_GRAPH=http://www.example.com/my-graph \
        -v /my/path/to/the/virtuoso/db:/data \
        -d xgaia/virtuoso

## Pull from DockerHub

    docker pull xgaia/virtuoso
