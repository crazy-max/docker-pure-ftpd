FROM --platform=${TARGETPLATFORM:-linux/amd64} alpine:3.12 as builder

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
    libsodium-dev \
    mariadb-connector-c-dev \
    openldap-dev \
    postgresql-dev \
    openssl-dev \
    tar \
  && rm -rf /tmp/*

COPY patchs /tmp/

ENV PUREFTPD_VERSION="1.0.49"

WORKDIR /tmp/pure-ftpd
RUN curl -sSL "https://github.com/jedisct1/pure-ftpd/releases/download/${PUREFTPD_VERSION}/pure-ftpd-${PUREFTPD_VERSION}.tar.gz" | tar xz --strip 1 \
  && patch -p1 < ../minimal.patch \
  && ./configure \
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

FROM --platform=${TARGETPLATFORM:-linux/amd64} alpine:3.12

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

LABEL maintainer="CrazyMax" \
  org.opencontainers.image.created=$BUILD_DATE \
  org.opencontainers.image.url="https://github.com/crazy-max/docker-pure-ftpd" \
  org.opencontainers.image.source="https://github.com/crazy-max/docker-pure-ftpd" \
  org.opencontainers.image.version=$VERSION \
  org.opencontainers.image.revision=$VCS_REF \
  org.opencontainers.image.vendor="CrazyMax" \
  org.opencontainers.image.title="Pure-FTPd" \
  org.opencontainers.image.description="Pure-FTPd with MySQL, PostgreSQL and LDAP support" \
  org.opencontainers.image.licenses="MIT"

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
  && S6_ARCH=$(case ${TARGETPLATFORM:-linux/amd64} in \
    "linux/amd64")   echo "amd64"   ;; \
    "linux/arm/v6")  echo "arm"     ;; \
    "linux/arm/v7")  echo "armhf"   ;; \
    "linux/arm64")   echo "aarch64" ;; \
    "linux/386")     echo "x86"     ;; \
    "linux/ppc64le") echo "ppc64le" ;; \
    *)               echo ""        ;; esac) \
  && echo "S6_ARCH=$S6_ARCH" \
  && wget -q "https://github.com/just-containers/s6-overlay/releases/latest/download/s6-overlay-${S6_ARCH}.tar.gz" -qO "/tmp/s6-overlay-${S6_ARCH}.tar.gz" \
  && tar xzf /tmp/s6-overlay-${S6_ARCH}.tar.gz -C / \
  && s6-echo "s6-overlay installed" \
  && wget -q "https://github.com/just-containers/socklog-overlay/releases/latest/download/socklog-overlay-${S6_ARCH}.tar.gz" -qO "/tmp/socklog-overlay-${S6_ARCH}.tar.gz" \
  && tar xzf /tmp/socklog-overlay-${S6_ARCH}.tar.gz -C / \
  && rm -f /etc/socklog.rules/* \
  && rm -rf /tmp/* /var/cache/apk/*

COPY --from=builder /pure-ftpd /
COPY rootfs /

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS="2" \
  PURE_PASSWDFILE="/data/pureftpd.passwd" \
  PURE_DBFILE="/data/pureftpd.pdb" \
  TZ="UTC"

RUN mkdir -p /data

EXPOSE 2100 30000-30009
WORKDIR /data
VOLUME [ "/data" ]

ENTRYPOINT [ "/init" ]
