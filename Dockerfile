FROM scratch
FROM ubuntu:18.04
ARG VERSION=2.0.0

RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get -y install apt-utils \
    && apt-get -y install \
        maven \
        wget \
        git \
        python \
        openjdk-8-jdk-headless \
        patch

RUN cd /tmp \
    && wget http://mirror.linux-ia64.org/apache/atlas/${VERSION}/apache-atlas-${VERSION}-sources.tar.gz \
    && mkdir /tmp/atlas-src \
    && tar --strip 1 -xzvf apache-atlas-${VERSION}-sources.tar.gz -C /tmp/atlas-src \
    && rm apache-atlas-${VERSION}-sources.tar.gz \
    && cd /tmp/atlas-src \
    && wget --no-check-certificate https://github.com/apache/atlas/pull/20.patch \
    && git apply ./20.patch \
    && export MAVEN_OPTS="-Xms2g -Xmx2g" \
    && export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64" \
    && mvn clean -DskipTests package -Pdist,embedded-hbase-solr \
    && tar -xzvf /tmp/atlas-src/distro/target/apache-atlas-${VERSION}-server.tar.gz -C /opt \
    && mv /opt/apache-atlas-${VERSION} /opt/apache-atlas/ \
    && rm -Rf /tmp/atlas-src

COPY atlas_start.py.patch atlas_config.py.patch /opt/apache-atlas/bin/
COPY pre-conf/atlas-application.properties /opt/apache-atlas/conf/atlas-application.properties
COPY pre-conf/atlas-env.sh /opt/apache-atlas/conf/atlas-env.sh
COPY pre-conf/atlas-log4j.xml /opt/apache-atlas/conf/atlas-log4j.xml

RUN cd /opt/apache-atlas/bin \
    && patch -b -f < atlas_start.py.patch \
    && patch -b -f < atlas_config.py.patch

RUN cd /opt/apache-atlas/bin \
    && ./atlas_start.py -setup || true

WORKDIR /opt/apache-atlas

ENTRYPOINT [ "bin/atlas_start.py" ]
