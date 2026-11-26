# syntax=docker/dockerfile:1

# renovate: datasource=github-tags depName=jedisct1/pure-ftpd
ARG PUREFTPD_VERSION=1.0.54
ARG PUREFTPD_COMMIT=3fe02789c4f0e5756f3f612e32edee9aa5d49455
# renovate: datasource=docker depName=alpine versioning=docker
ARG ALPINE_VERSION=3.24
# renovate: datasource=docker depName=tonistiigi/xx versioning=docker
ARG XX_VERSION=1.10.0

FROM --platform=${BUILDPLATFORM} tonistiigi/xx:${XX_VERSION} AS xx

FROM --platform=${BUILDPLATFORM} alpine:${ALPINE_VERSION} AS builder
COPY --from=xx / /
RUN apk --update --no-cache add autoconf automake binutils clang file make pkgconf tar xz
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
ARG PUREFTPD_VERSION
ARG PUREFTPD_COMMIT
ADD --checksum=${PUREFTPD_COMMIT} https://github.com/jedisct1/pure-ftpd.git#${PUREFTPD_VERSION} .
RUN <<EOT
  set -ex
  ./autogen.sh
  CC=xx-clang ./configure \
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
    --with-tls \
    --with-uploadscript \
    --with-brokenrealpath \
    --with-certfile=/data/pureftpd.pem
  make install
  xx-verify /out/sbin/pure-ftpd
  xx-verify /out/sbin/pure-uploadscript
  file /out/sbin/pure-ftpd
EOT

FROM alpine:${ALPINE_VERSION}

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS="2" \
  S6_STAGE2_HOOK="/etc/s6-overlay/scripts/runtime-bundles" \
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
    s6-overlay \
    tzdata \
    zlib \
  && rm -rf /tmp/*

COPY --from=builder /out /
COPY rootfs /

EXPOSE 2100 30000-30009
WORKDIR /data
VOLUME [ "/data" ]

ENTRYPOINT [ "/init" ]
