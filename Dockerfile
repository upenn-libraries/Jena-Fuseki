FROM eclipse-temurin:17-jre-alpine

FROM ubuntu:24.04

ENV ASF_ARCHIVE="https://archive.apache.org/dist/"
ENV ASF_MIRROR="https://www.apache.org/dyn/mirrors/mirrors.cgi?action=download&filename="
ENV DEBIAN_FRONTEND="noninteractive"
ENV FUSEKI_BASE="/fuseki"
ENV FUSEKI_HOME="/jena-fuseki"
ENV FUSEKI_SHA512="62ac07f70c65a77fb90127635fa82f719fd5f4f10339c32702ebd664227d78f7414233d69d5b73f25b033f2fdea37b8221ea498755697eea3c1344819e4a527e"
ENV FUSEKI_VERSION="3.14.0"
ENV JRE_PACKAGE="openjdk-11-jre"
ENV LANG="C.UTF-8"

WORKDIR /tmp

COPY . /tmp
RUN mv docker-entrypoint.sh / && \
    mkdir -p $FUSEKI_HOME && \
    mv * $FUSEKI_HOME/ && \
    chmod 755 /docker-entrypoint.sh \
      $FUSEKI_HOME/load.sh \
      $FUSEKI_HOME/tdbloader \
      $FUSEKI_HOME/tdbloader2

RUN apt-get update && \
    apt-get install -y \
      ca-certificates \
      coreutils \
      curl \
      findutils \
      gettext \
      ${JRE_PACKAGE} \
      procps \
      pwgen \
      tini && \
    apt-get clean

RUN echo "$FUSEKI_SHA512  fuseki.tar.gz" > fuseki.tar.gz.sha512

RUN (curl --location --silent --show-error --fail --retry-connrefused --retry 3 --output fuseki.tar.gz ${ASF_MIRROR}jena/binaries/apache-jena-fuseki-$FUSEKI_VERSION.tar.gz || \
    curl --fail --silent --show-error --retry-connrefused --retry 3 --output fuseki.tar.gz $ASF_ARCHIVE/jena/binaries/apache-jena-fuseki-$FUSEKI_VERSION.tar.gz) && \
    sha512sum -c fuseki.tar.gz.sha512 && \
    tar zxf fuseki.tar.gz && \
    mv apache-jena-fuseki-${FUSEKI_VERSION}/* $FUSEKI_HOME && \
    rm fuseki.tar.gz*

WORKDIR $FUSEKI_HOME

RUN rm -rf fuseki.war && \
    chmod 755 fuseki-server

# Test the install by testing it's ping resource. 20s sleep because Docker Hub.
RUN ./fuseki-server & \
    sleep 20 && \
    curl -sS --fail 'http://localhost:3030/$/ping' 

# Create a fuseki user and group
RUN addgroup --system fuseki && \
    adduser --system --group fuseki --disabled-password --home /home/fuseki

# Where we start our server from
RUN chown -R fuseki:fuseki $FUSEKI_HOME

# Make sure we start with empty /fuseki
RUN mkdir -p $FUSEKI_BASE; \
    rm -rf $FUSEKI_BASE/*; \
    chown -R fuseki:fuseki $FUSEKI_BASE

    VOLUME $FUSEKI_BASE

EXPOSE 3030
USER fuseki

ENTRYPOINT ["/sbin/tini", "--", "sh", "/docker-entrypoint.sh"]
CMD ["/jena-fuseki/fuseki-server"]
