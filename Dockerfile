# syntax=docker/dockerfile:experimental
FROM --platform=${TARGETPLATFORM:-linux/amd64} alpine:3.11 as builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM
RUN printf "I am running on ${BUILDPLATFORM:-linux/amd64}, building for ${TARGETPLATFORM:-linux/amd64}\n$(uname -a)\n"

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

RUN apk --update --no-cache add \
    autoconf \
    automake \
    binutils \
    build-base \
    curl \
    libsodium \
    mariadb-connector-c-dev \
    openldap-dev \
    postgresql-dev \
    openssl-dev \
    tar \
  && rm -rf /tmp/*

COPY patchs /tmp/

ENV PUREFTPD_VERSION="1.0.49"

WORKDIR /tmp/pure-ftpd
RUN curl -sSL "https://download.pureftpd.org/pub/pure-ftpd/releases/pure-ftpd-${PUREFTPD_VERSION}.tar.gz" | tar xz --strip 1 \
  && patch -p1 < ../minimal.patch \
  && ./configure \
    --prefix=/pure-ftpd \
    --without-humor \
    --without-inetd \
    --with-altlog \
    --with-cookie \
    --with-ftpwho \
    --with-ldap \
    --with-mysql \
    --with-pgsql \
    --with-puredb \
    --with-quotas \
    --with-ratios \
    --with-throttling \
    --with-tls \
    --with-uploadscript \
    --with-certfile=/data/pureftpd.pem \
    --with-certfile=/data/pureftpd.pem \
  && make install-strip

# syntax=docker/dockerfile:experimental
FROM --platform=${TARGETPLATFORM:-linux/amd64} alpine:3.11

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

LABEL maintainer="CrazyMax" \
  org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.name="pure-ftpd" \
  org.label-schema.description="Pure-FTPd with MySQL, PostgreSQL and LDAP support" \
  org.label-schema.version=$VERSION \
  org.label-schema.url="https://github.com/crazy-max/docker-pure-ftpd" \
  org.label-schema.vcs-ref=$VCS_REF \
  org.label-schema.vcs-url="https://github.com/crazy-max/docker-pure-ftpd" \
  org.label-schema.vendor="CrazyMax" \
  org.label-schema.schema-version="1.0"

RUN apk --update --no-cache add \
    bind-tools \
    libldap \
    libpq \
    libsodium \
    mariadb-connector-c \
    mysql-client \
    openldap-clients \
    openssl \
    postgresql-client \
    supervisor \
    tzdata \
    zlib \
  && apk --update --no-cache add --repository=http://dl-cdn.alpinelinux.org/alpine/edge/main \
    syslog-ng \
  && rm -rf /tmp/* /var/cache/apk/*

COPY --from=builder /pure-ftpd /
COPY entrypoint.sh /entrypoint.sh
COPY stop-supervisor.sh /stop-supervisor.sh
COPY assets /

ENV PURE_PASSWDFILE="/data/pureftpd.passwd" \
  PURE_DBFILE="/data/pureftpd.pdb" \
  TZ="UTC"

RUN chmod a+x /entrypoint.sh /stop-supervisor.sh \
  && mkdir -p /data

EXPOSE 2100 30000-30009
WORKDIR /data
VOLUME [ "/data" ]

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/usr/bin/supervisord", "-c", "/etc/supervisord.conf" ]
