# Compile virtuoso in a separate image
FROM alpine:3.20 AS builder

# Environment variables
ENV VIRTUOSO_GIT_URL=https://github.com/openlink/virtuoso-opensource.git
ENV VIRTUOSO_DIR=/virtuoso-opensource
ENV VIRTUOSO_GIT_VERSION=7.2.14

COPY patch.diff /patch.diff

# Install prerequisites
RUN apk add --update git automake autoconf automake libtool bison flex gawk gperf openssl \
    g++ openssl-dev make patch xz-dev bzip2-dev python3
# Download sources
RUN git clone -b v${VIRTUOSO_GIT_VERSION} --single-branch --depth=1 ${VIRTUOSO_GIT_URL} ${VIRTUOSO_DIR}
WORKDIR ${VIRTUOSO_DIR}
# Patch
RUN patch ${VIRTUOSO_DIR}/libsrc/Wi/sparql_io.sql < /patch.diff
# Complile
RUN  ./autogen.sh
RUN CFLAGS="-O2 -m64" && export CFLAGS && \
    ./configure --disable-bpel-vad --enable-conductor-vad --enable-fct-vad --disable-dbpedia-vad --disable-demo-vad --disable-isparql-vad --disable-ods-vad --disable-sparqldemo-vad --disable-syncml-vad --disable-tutorial-vad --program-transform-name="s/isql/isql-v/"
RUN make -j $(grep -c '^processor' /proc/cpuinfo)
# Install
RUN make -j $(grep -c '^processor' /proc/cpuinfo) install

# Final image
FROM alpine:3.20
ENV PATH=/usr/local/virtuoso-opensource/bin/:/root/.local/bin:$PATH

RUN apk add --no-cache --update openssl s3fs-fuse fuse libcurl libxml2 pipx && \
    pipx install crudini && \
    mkdir -p /usr/local/virtuoso-opensource/var/lib/virtuoso/db && \
    ln -s /usr/local/virtuoso-opensource/var/lib/virtuoso/db /data

COPY --from=builder /usr/local/virtuoso-opensource /usr/local/virtuoso-opensource
COPY virtuoso.ini dump_nquads_procedure.sql dump_one_graph_procedure.sql clean-logs.sh virtuoso.sh /virtuoso/

WORKDIR /data
EXPOSE 8890 1111

CMD ["/virtuoso/virtuoso.sh"]
