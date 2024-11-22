# Compile s3fs in a separate image
FROM alpine:3.20 AS s3fs-builder
RUN apk add --update fuse fuse-dev automake gcc make libcurl curl-dev libxml2 libxml2-dev \
    openssl openssl-dev autoconf g++
RUN wget https://github.com/s3fs-fuse/s3fs-fuse/archive/refs/tags/v1.91.zip && \
    unzip v1.91.zip
WORKDIR s3fs-fuse-1.91
RUN ./autogen.sh && ./configure && make && make install

# Compile virtuoso in a separate image
FROM alpine:3.20 AS builder

# Environment variables
ENV VIRTUOSO_GIT_URL=https://github.com/openlink/virtuoso-opensource.git
ENV VIRTUOSO_DIR=/virtuoso-opensource
ENV VIRTUOSO_GIT_VERSION=7.2.14

COPY patch.diff /patch.diff

# Install prerequisites
RUN apk add --update git automake autoconf automake libtool bison flex gawk gperf openssl \
    g++ openssl-dev make patch xz-dev bzip2-dev
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
ENV PATH=/usr/local/virtuoso-opensource/bin/:$PATH
COPY --from=s3fs-builder  /usr/local/bin/s3fs /usr/local/bin/s3fs

RUN apk add --no-cache --update openssl py-pip fuse libcurl libxml2 && \
    pip install crudini && \
    mkdir -p /usr/local/virtuoso-opensource/var/lib/virtuoso/db && \
    ln -s /usr/local/virtuoso-opensource/var/lib/virtuoso/db /data

COPY --from=builder /usr/local/virtuoso-opensource /usr/local/virtuoso-opensource
COPY virtuoso.ini dump_nquads_procedure.sql dump_one_graph_procedure.sql clean-logs.sh virtuoso.sh /virtuoso/

WORKDIR /data
EXPOSE 8890 1111

CMD sh /virtuoso/virtuoso.sh
