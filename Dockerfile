ARG UID_GID="35002:35002"

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
    && gpg --verify /tika-server-standard-${TIKA_VERSION}.jar.asc /tika-server-standard-${TIKA_VERSION}.jar \
    && wget -t 10 --max-redirect 1 --retry-connrefused $DEFAULT_TIKA_FETCHER_GCS_URL -O /tika-fetcher-gcs-${TIKA_VERSION}.jar \
    && wget -t 10 --max-redirect 1 --retry-connrefused $DEFAULT_TIKA_FETCHER_GCS_ASC_URL -O /tika-fetcher-gcs-${TIKA_VERSION}.jar.asc \
    && gpg --verify /tika-fetcher-gcs-${TIKA_VERSION}.jar.asc /tika-fetcher-gcs-${TIKA_VERSION}.jar

FROM base AS runtime
ARG UID_GID
ARG JRE='openjdk-21-jre-headless'
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
ARG TIKA_VERSION
ENV TIKA_VERSION=$TIKA_VERSION

COPY --from=fetch_tika /tika-server-standard-${TIKA_VERSION}.jar /tika-server-standard-${TIKA_VERSION}.jar
COPY --from=fetch_tika /tika-fetcher-gcs-${TIKA_VERSION}.jar /tika-fetcher-gcs-${TIKA_VERSION}.jar

USER $UID_GID

EXPOSE 9998
ENTRYPOINT [ "/bin/sh", "-c", "exec java -cp \"/tika-server-standard-${TIKA_VERSION}.jar:/tika-fetcher-gcs-${TIKA_VERSION}.jar\" org.apache.tika.server.core.TikaServerCli -h 0.0.0.0 $0 $@" ]
