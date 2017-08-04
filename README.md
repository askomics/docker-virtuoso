# docker-virtuoso

![Docker Build](https://img.shields.io/docker/pulls/xgaia/virtuoso.svg)

Virtuoso dockerized, based on Alpine

Based on [tenforce/docker-virtuoso](https://github.com/tenforce/docker-virtuoso) and [jplu/docker-virtuoso](https://github.com/jplu/docker-virtuoso)

## Pull from DockerHub

    docker pull xgaia/virtuoso

## Or build

    # Clone the repo
    git clone https://github.com/xgaia/docker-virtuoso.git
    cd docker-virtuoso
    # Build image
    docker build -t virtuoso .


## RUN

    docker run --name my-virtuoso \
        -p 8890:8890 -p 1111:1111 \
        -e DBA_PASSWORD=myDbaPassword \
        -e SPARQL_UPDATE=true \
        -e DEFAULT_GRAPH=http://www.example.com/my-graph \
        -v /my/path/to/the/virtuoso/db:/data \
        -d xgaia/virtuoso
