# docker-virtuoso

![Docker Build](https://img.shields.io/docker/pulls/askomics/virtuoso.svg)
[![Build Status](https://travis-ci.org/askomics/docker-virtuoso.svg?branch=master)](https://travis-ci.org/askomics/docker-virtuoso)


Virtuoso dockerized, based on Alpine

Based on [tenforce/docker-virtuoso](https://github.com/tenforce/docker-virtuoso) and [jplu/docker-virtuoso](https://github.com/jplu/docker-virtuoso).

Image have the same functionalities than [tenforce/docker-virtuoso](https://github.com/tenforce/docker-virtuoso), but it is lighter (347MB instead of 496MB)

## Pull from DockerHub

    docker pull askomics/virtuoso

## Or build

    # Clone the repo
    git clone https://github.com/askomics/docker-virtuoso.git
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
        -d askomics/virtuoso
