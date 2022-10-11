FROM alpine:3.16 AS builder
MAINTAINER Xavier Garnier 'xavier.garnier@irisa.fr'

# Environment variables
ENV VIRTUOSO_GIT_URL https://github.com/openlink/virtuoso-opensource.git
ENV VIRTUOSO_DIR /virtuoso-opensource
ENV VIRTUOSO_GIT_VERSION 7.2.7

COPY patch.diff /patch.diff

# Install prerequisites, Download, Patch, compile and install
RUN apk add --update git automake autoconf automake libtool bison flex gawk gperf openssl g++ openssl-dev make patch && \
    git clone -b v${VIRTUOSO_GIT_VERSION} --single-branch --depth=1 ${VIRTUOSO_GIT_URL} ${VIRTUOSO_DIR} && \
    cd ${VIRTUOSO_DIR} && \
    patch ${VIRTUOSO_DIR}/libsrc/Wi/sparql_io.sql < /patch.diff && \
    ./autogen.sh && \
    CFLAGS="-O2 -m64" && export CFLAGS && \
    ./configure --disable-bpel-vad --enable-conductor-vad --enable-fct-vad --disable-dbpedia-vad --disable-demo-vad --disable-isparql-vad --disable-ods-vad --disable-sparqldemo-vad --disable-syncml-vad --disable-tutorial-vad --program-transform-name="s/isql/isql-v/" && \
    make -j $(grep -c '^processor' /proc/cpuinfo) && \
    make -j $(grep -c '^processor' /proc/cpuinfo) install


# Final image
FROM alpine:3.16
ENV PATH /usr/local/virtuoso-opensource/bin/:$PATH
RUN apk add --no-cache --update openssl py-pip && \
    pip install crudini && \
    mkdir -p /usr/local/virtuoso-opensource/var/lib/virtuoso/db && \
    ln -s /usr/local/virtuoso-opensource/var/lib/virtuoso/db /data && \
    apk add --no-cache --update s3fs-fuse --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/

COPY --from=builder /usr/local/virtuoso-opensource /usr/local/virtuoso-opensource
COPY virtuoso.ini dump_nquads_procedure.sql dump_one_graph_procedure.sql clean-logs.sh virtuoso.sh /virtuoso/

WORKDIR /data
EXPOSE 8890 1111

CMD sh /virtuoso/virtuoso.sh
