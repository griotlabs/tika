ARG UID_GID="35002:35002"
ARG TIKA_VERSION=3.1.0

FROM ubuntu:oracular AS base

FROM base AS fetch_tika

ARG TIKA_VERSION

ENV NEAREST_TIKA_SERVER_URL="https://dlcdn.apache.org/tika/${TIKA_VERSION}/tika-server-standard-${TIKA_VERSION}.jar" \
    ARCHIVE_TIKA_SERVER_URL="https://archive.apache.org/dist/tika/${TIKA_VERSION}/tika-server-standard-${TIKA_VERSION}.jar" \
    BACKUP_TIKA_SERVER_URL="https://downloads.apache.org/tika/${TIKA_VERSION}/tika-server-standard-${TIKA_VERSION}.jar" \
    DEFAULT_TIKA_SERVER_ASC_URL="https://downloads.apache.org/tika/${TIKA_VERSION}/tika-server-standard-${TIKA_VERSION}.jar.asc" \
    ARCHIVE_TIKA_SERVER_ASC_URL="https://archive.apache.org/dist/tika/${TIKA_VERSION}/tika-server-standard-${TIKA_VERSION}.jar.asc" \
    DEFAULT_TIKA_FETCHER_GCS_URL="https://repo1.maven.org/maven2/org/apache/tika/tika-fetcher-gcs/${TIKA_VERSION}/tika-fetcher-gcs-${TIKA_VERSION}.jar" \
    DEFAULT_TIKA_FETCHER_GCS_ASC_URL="https://repo1.maven.org/maven2/org/apache/tika/tika-fetcher-gcs/${TIKA_VERSION}/tika-fetcher-gcs-${TIKA_VERSION}.jar.asc" \
    TIKA_VERSION=$TIKA_VERSION

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get -y install gnupg2 wget ca-certificates \
    && wget -t 10 --max-redirect 1 --retry-connrefused -qO- https://downloads.apache.org/tika/KEYS | gpg --import \
    && wget -t 10 --max-redirect 1 --retry-connrefused $NEAREST_TIKA_SERVER_URL -O /tika-server-standard-${TIKA_VERSION}.jar || rm /tika-server-standard-${TIKA_VERSION}.jar \
    && sh -c "[ -f /tika-server-standard-${TIKA_VERSION}.jar ]" || wget $ARCHIVE_TIKA_SERVER_URL -O /tika-server-standard-${TIKA_VERSION}.jar || rm /tika-server-standard-${TIKA_VERSION}.jar \
    && sh -c "[ -f /tika-server-standard-${TIKA_VERSION}.jar ]" || wget $BACKUP_TIKA_SERVER_URL -O /tika-server-standard-${TIKA_VERSION}.jar || rm /tika-server-standard-${TIKA_VERSION}.jar \
    && sh -c "[ -f /tika-server-standard-${TIKA_VERSION}.jar ]" || exit 1 \
    && wget -t 10 --max-redirect 1 --retry-connrefused $DEFAULT_TIKA_SERVER_ASC_URL -O /tika-server-standard-${TIKA_VERSION}.jar.asc  || rm /tika-server-standard-${TIKA_VERSION}.jar.asc \
    && sh -c "[ -f /tika-server-standard-${TIKA_VERSION}.jar.asc ]" || wget $ARCHIVE_TIKA_SERVER_ASC_URL -O /tika-server-standard-${TIKA_VERSION}.jar.asc || rm /tika-server-standard-${TIKA_VERSION}.jar.asc \
    && sh -c "[ -f /tika-server-standard-${TIKA_VERSION}.jar.asc ]" || exit 1 \
    && gpg --verify /tika-server-standard-${TIKA_VERSION}.jar.asc /tika-server-standard-${TIKA_VERSION}.jar

RUN wget -t 10 --max-redirect 1 --retry-connrefused https://repo1.maven.org/maven2/org/apache/tika/tika-fetcher-gcs/${TIKA_VERSION}/tika-fetcher-gcs-${TIKA_VERSION}.jar -O /tika-fetcher-gcs-${TIKA_VERSION}.jar \
    && wget -t 10 --max-redirect 1 --retry-connrefused https://repo1.maven.org/maven2/org/apache/tika/tika-fetcher-gcs/${TIKA_VERSION}/tika-fetcher-gcs-${TIKA_VERSION}.jar.asc -O /tika-fetcher-gcs-${TIKA_VERSION}.jar.asc \
    && gpg --verify /tika-fetcher-gcs-${TIKA_VERSION}.jar.asc /tika-fetcher-gcs-${TIKA_VERSION}.jar \
    && wget -t 10 --max-redirect 1 --retry-connrefused https://repo1.maven.org/maven2/org/apache/tika/tika-emitter-gcs/${TIKA_VERSION}/tika-emitter-gcs-${TIKA_VERSION}.jar -O /tika-emitter-gcs-${TIKA_VERSION}.jar \
    && wget -t 10 --max-redirect 1 --retry-connrefused https://repo1.maven.org/maven2/org/apache/tika/tika-emitter-gcs/${TIKA_VERSION}/tika-emitter-gcs-${TIKA_VERSION}.jar.asc -O /tika-emitter-gcs-${TIKA_VERSION}.jar.asc \
    && gpg --verify /tika-emitter-gcs-${TIKA_VERSION}.jar.asc /tika-emitter-gcs-${TIKA_VERSION}.jar

RUN wget -t 10 --max-redirect 1 --retry-connrefused https://repo1.maven.org/maven2/org/apache/tika/tika-fetcher-s3/${TIKA_VERSION}/tika-fetcher-s3-${TIKA_VERSION}.jar -O /tika-fetcher-s3-${TIKA_VERSION}.jar \
    && wget -t 10 --max-redirect 1 --retry-connrefused https://repo1.maven.org/maven2/org/apache/tika/tika-fetcher-s3/${TIKA_VERSION}/tika-fetcher-s3-${TIKA_VERSION}.jar.asc -O /tika-fetcher-s3-${TIKA_VERSION}.jar.asc \
    && gpg --verify /tika-fetcher-s3-${TIKA_VERSION}.jar.asc /tika-fetcher-s3-${TIKA_VERSION}.jar \
    && wget -t 10 --max-redirect 1 --retry-connrefused https://repo1.maven.org/maven2/org/apache/tika/tika-emitter-s3/${TIKA_VERSION}/tika-emitter-s3-${TIKA_VERSION}.jar -O /tika-emitter-s3-${TIKA_VERSION}.jar \
    && wget -t 10 --max-redirect 1 --retry-connrefused https://repo1.maven.org/maven2/org/apache/tika/tika-emitter-s3/${TIKA_VERSION}/tika-emitter-s3-${TIKA_VERSION}.jar.asc -O /tika-emitter-s3-${TIKA_VERSION}.jar.asc \
    && gpg --verify /tika-emitter-s3-${TIKA_VERSION}.jar.asc /tika-emitter-s3-${TIKA_VERSION}.jar

FROM base AS runtime

ARG UID_GID
ARG JRE='openjdk-21-jre-headless'
ARG TIKA_VERSION

RUN set -eux \
    && apt-get update \
    && apt-get install --yes --no-install-recommends gnupg2 software-properties-common \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends $JRE \
        gdal-bin \
        tesseract-ocr \
        tesseract-ocr-eng \
        tesseract-ocr-ita \
        tesseract-ocr-fra \
        tesseract-ocr-spa \
        tesseract-ocr-deu \
    && echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections \
    && DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
        xfonts-utils \
        fonts-freefont-ttf \
        fonts-liberation \
        ttf-mscorefonts-installer \
        wget \
        cabextract \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV TIKA_VERSION=$TIKA_VERSION
ENV OMP_THREAD_LIMIT=1

RUN mkdir /tika-bin

RUN mkdir -p /config && chown $UID_GID /config && chmod 755 /config

COPY --from=fetch_tika /tika-server-standard-${TIKA_VERSION}.jar /tika-bin/tika-server-standard-${TIKA_VERSION}.jar
COPY --from=fetch_tika /tika-fetcher-gcs-${TIKA_VERSION}.jar /tika-bin/tika-fetcher-gcs-${TIKA_VERSION}.jar
COPY --from=fetch_tika /tika-emitter-gcs-${TIKA_VERSION}.jar /tika-bin/tika-emitter-gcs-${TIKA_VERSION}.jar
COPY --from=fetch_tika /tika-fetcher-s3-${TIKA_VERSION}.jar /tika-bin/tika-fetcher-s3-${TIKA_VERSION}.jar
COPY --from=fetch_tika /tika-emitter-s3-${TIKA_VERSION}.jar /tika-bin/tika-emitter-s3-${TIKA_VERSION}.jar
COPY tika-config.xml /config/tika-config.xml
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh && chown $UID_GID /entrypoint.sh

USER $UID_GID

EXPOSE 9998
ENTRYPOINT ["/entrypoint.sh"]
