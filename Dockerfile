ARG PUREFTPD_VERSION=1.0.49

FROM --platform=${BUILDPLATFORM:-linux/amd64} crazymax/alpine-s6:3.13-2.2.0.3 AS download
RUN apk --update --no-cache add curl patch tar

ARG PUREFTPD_VERSION
WORKDIR /dist/pureftpd
COPY patchs /dist
RUN curl -sSL "https://github.com/jedisct1/pure-ftpd/releases/download/${PUREFTPD_VERSION}/pure-ftpd-${PUREFTPD_VERSION}.tar.gz" | tar xz --strip 1 \
  && patch -p1 < ../minimal.patch

FROM crazymax/alpine-s6:3.13-2.2.0.3 AS builder
RUN apk --update --no-cache add \
    autoconf \
    automake \
    binutils \
    build-base \
    libsodium-dev \
    mariadb-connector-c-dev \
    openldap-dev \
    postgresql-dev \
    openssl-dev \
  && rm -rf /tmp/*

COPY --from=download /dist/pureftpd /tmp/pureftpd
WORKDIR /tmp/pureftpd
RUN ./configure \
    --prefix=/pure-ftpd \
    --without-humor \
    --without-inetd \
    --without-pam \
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
    --with-brokenrealpath \
    --with-certfile=/data/pureftpd.pem \
  && make install-strip

FROM crazymax/alpine-s6:3.13-2.2.0.3

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS="2" \
  SOCKLOG_TIMESTAMP_FORMAT="" \
  PURE_PASSWDFILE="/data/pureftpd.passwd" \
  PURE_DBFILE="/data/pureftpd.pdb" \
  TZ="UTC"

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
    tzdata \
    zlib \
  && rm -f /etc/socklog.rules/* \
  && rm -rf /tmp/* /var/cache/apk/*

COPY --from=builder /pure-ftpd /
COPY rootfs /

RUN mkdir -p /data \
  && pure-ftpwho --help

EXPOSE 2100 30000-30009
WORKDIR /data
VOLUME [ "/data" ]

ENTRYPOINT [ "/init" ]
