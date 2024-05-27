# syntax=docker/dockerfile:1

ARG PUREFTPD_VERSION=1.0.50
ARG ALPINE_VERSION=3.17
ARG XX_VERSION=1.2.1

FROM --platform=${BUILDPLATFORM} tonistiigi/xx:${XX_VERSION} AS xx

FROM --platform=${BUILDPLATFORM} crazymax/alpine-s6:${ALPINE_VERSION}-2.2.0.3 AS src
COPY --from=xx / /
RUN apk --update --no-cache add git patch
WORKDIR /src/pure-ftpd
RUN git init . && git remote add origin "https://github.com/jedisct1/pure-ftpd.git"
ARG PUREFTPD_VERSION
RUN git fetch origin "${PUREFTPD_VERSION}" && git checkout -q FETCH_HEAD
COPY patchs /src
RUN patch -p1 < ../minimal.patch

FROM --platform=${BUILDPLATFORM} crazymax/alpine-s6:${ALPINE_VERSION}-2.2.0.3 AS builder
COPY --from=xx / /
RUN apk --update --no-cache add autoconf automake binutils clang14 file make pkgconf tar xz
ENV XX_CC_PREFER_LINKER=ld
ARG TARGETPLATFORM
RUN xx-apk --no-cache --update add \
    gcc \
    linux-headers \
    musl-dev \
    libsodium-dev \
    mariadb-connector-c-dev \
    openldap-dev \
    postgresql-dev \
    openssl-dev
WORKDIR /src
COPY --from=src /src/pure-ftpd /src
RUN <<EOT
  set -ex
  ./autogen.sh
  ./configure \
    --host=$(xx-clang --print-target-triple) \
    --prefix=/out \
    --without-ascii \
    --without-humor \
    --without-inetd \
    --without-pam \
    --with-altlog \
    --with-cookie \
    --with-ftpwho \
    --with-ldap=$(xx-info sysroot)usr \
    --with-mysql=$(xx-info sysroot)usr \
    --with-pgsql=$(xx-info sysroot)usr \
    --with-puredb \
    --with-quotas \
    --with-ratios \
    --with-throttling \
    --with-tls=$(xx-info sysroot)usr \
    --with-uploadscript \
    --with-brokenrealpath \
    --with-certfile=/data/pureftpd.pem
  make install
  xx-verify /out/sbin/pure-ftpd
  xx-verify /out/sbin/pure-uploadscript
  file /out/sbin/pure-ftpd
EOT

FROM crazymax/alpine-s6:${ALPINE_VERSION}-2.2.0.3

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS="2" \
  SOCKLOG_TIMESTAMP_FORMAT="" \
  PURE_PASSWDFILE="/data/pureftpd.passwd" \
  PURE_DBFILE="/data/pureftpd.pdb" \
  TZ="UTC"

RUN apk --update --no-cache add \
    bind-tools \
    curl \
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
  && rm -rf /tmp/*

COPY --from=builder /out /
COPY rootfs /

EXPOSE 2100 30000-30009
WORKDIR /data
VOLUME [ "/data" ]

ENTRYPOINT [ "/init" ]
