#!/bin/sh

AUTH_METHOD=${AUTH_METHOD:-puredb}
SECURE_MODE=${SECURE_MODE:-true}
PASSIVE_IP=${PASSIVE_IP:-$(dig +short myip.opendns.com @resolver1.opendns.com)}
DB_TIMEOUT=${DB_TIMEOUT:-45}

extractFromConf() {
  awk -F' ' "/^${1}/ { print \$2 }" < "$2"
}

PFTPD_FLAGS="/data/pureftpd.flags"
PFTPD_PUREDB="/data/pureftpd.pdb"
PFTPD_PASSWD="/data/pureftpd.passwd"
PFTPD_MYSQL_CONF="/data/pureftpd-mysql.conf"
PFTPD_PGSQL_CONF="/data/pureftpd-pgsql.conf"
PFTPD_LDAP_CONF="/data/pureftpd-ldap.conf"
PFTPD_PEM="/data/pureftpd.pem"

ADD_FLAGS=""
if [ -f "${PFTPD_FLAGS}" ]; then
  while read FLAG; do
    test -z "$FLAG" && continue
    ADD_FLAGS="$ADD_FLAGS $FLAG"
  done < ${PFTPD_FLAGS}
  FLAGS="$FLAGS$ADD_FLAGS"
fi

FLAGS="$FLAGS --bind 0.0.0.0,2100"
FLAGS="$FLAGS --ipv4only"
FLAGS="$FLAGS --passiveportrange 30000:30009"
FLAGS="$FLAGS --noanonymous"
FLAGS="$FLAGS --createhomedir"
FLAGS="$FLAGS --nochmod"
FLAGS="$FLAGS --syslogfacility ftp"

if [ -n "$PASSIVE_IP" ]; then
  FLAGS="$FLAGS --forcepassiveip $PASSIVE_IP"
fi

# Secure mode
SECURE_FLAGS=""
if [ "$SECURE_MODE" = "true" ]; then
  SECURE_FLAGS="$SECURE_FLAGS --maxclientsnumber 5"
  SECURE_FLAGS="$SECURE_FLAGS --maxclientsperip 5"
  SECURE_FLAGS="$SECURE_FLAGS --antiwarez"
  SECURE_FLAGS="$SECURE_FLAGS --customerproof"
  SECURE_FLAGS="$SECURE_FLAGS --dontresolve"
  SECURE_FLAGS="$SECURE_FLAGS --norename"
  SECURE_FLAGS="$SECURE_FLAGS --prohibitdotfilesread"
  SECURE_FLAGS="$SECURE_FLAGS --prohibitdotfileswrite"
  FLAGS="$FLAGS$SECURE_FLAGS"
fi

# MySQL auth
if [ "$AUTH_METHOD" = "mysql" ]; then
  FLAGS="$FLAGS --login mysql:${PFTPD_MYSQL_CONF}"
  if [ ! -f "${PFTPD_MYSQL_CONF}" ]; then
    >&2 echo "ERROR: ${PFTPD_MYSQL_CONF} does not exist"
    exit 1
  fi
  echo "Use MySQL authentication method"

  DB_HOST=$(extractFromConf "MYSQLServer" ${PFTPD_MYSQL_CONF})
  DB_PORT=$(extractFromConf "MYSQLPort" ${PFTPD_MYSQL_CONF})
  DB_USER=$(extractFromConf "MYSQLUser" ${PFTPD_MYSQL_CONF})
  DB_PASSWORD=$(extractFromConf "MYSQLPassword" ${PFTPD_MYSQL_CONF})
  DB_CMD="mysql -h ${DB_HOST} -P ${DB_PORT} -u ${DB_USER} "-p${DB_PASSWORD}""
  #echo "DB_CMD=$DB_CMD"

  echo "Waiting ${DB_TIMEOUT}s for MySQL database to be ready..."
  counter=1
  while ! ${DB_CMD} -e "show databases;" > /dev/null 2>&1; do
      sleep 1
      counter=$((counter + 1))
      if [ ${counter} -gt "${DB_TIMEOUT}" ]; then
          >&2 echo "ERROR: Failed to connect to MySQL database on $DB_HOST"
          exit 1
      fi;
  done
  echo "MySQL database ready!"
  unset DB_USER DB_PASSWORD DB_CMD

# PostgreSQL auth
elif [ "$AUTH_METHOD" = "pgsql" ]; then
  FLAGS="$FLAGS --login pgsql:${PFTPD_PGSQL_CONF}"p
  if [ ! -f "${PFTPD_PGSQL_CONF}" ]; then
    >&2 echo "ERROR: ${PFTPD_PGSQL_CONF} does not exist"
    exit 1
  fi
  echo "Use PostgreSQL authentication method"

  DB_HOST=$(extractFromConf "PGSQLServer" ${PFTPD_PGSQL_CONF})
  DB_PORT=$(extractFromConf "PGSQLPort" ${PFTPD_PGSQL_CONF})
  DB_USER=$(extractFromConf "PGSQLUser" ${PFTPD_PGSQL_CONF})
  DB_PASSWORD=$(extractFromConf "PGSQLPassword" ${PFTPD_PGSQL_CONF})
  DB_NAME=$(extractFromConf "PGSQLDatabase" ${PFTPD_PGSQL_CONF})
  export PGPASSWORD=${DB_PASSWORD}
  DB_CMD="psql --host=${DB_HOST} --port=${DB_PORT} --username=${DB_USER} -lqt"
  #echo "DB_CMD=$DB_CMD"

  echo "Waiting ${DB_TIMEOUT}s for database to be ready..."
  counter=1
  while ${DB_CMD} | cut -d \| -f 1 | grep -qw "${DB_NAME}" > /dev/null 2>&1; [ $? -ne 0 ]; do
    sleep 1
    counter=$((counter + 1))
    if [ ${counter} -gt "${DB_TIMEOUT}" ]; then
      >&2 echo "ERROR: Failed to connect to PostgreSQL database on $DB_HOST"
      exit 1
    fi;
  done
  echo "PostgreSQL database ready!"
  unset DB_USER DB_PASSWORD DB_CMD

# LDAP auth
elif [ "$AUTH_METHOD" = "ldap" ]; then
  FLAGS="$FLAGS --login ldap:${PFTPD_LDAP_CONF}"
  if [ ! -f "${PFTPD_LDAP_CONF}" ]; then
    >&2 echo "ERROR: ${PFTPD_LDAP_CONF} does not exist"
    exit 1
  fi

# PureDB auth
else
  AUTH_METHOD="puredb"
  FLAGS="$FLAGS --login puredb:${PFTPD_PUREDB}"
  touch "${PFTPD_PUREDB}" "${PFTPD_PASSWD}"
  pure-pw mkdb "${PFTPD_PUREDB}" -f "${PFTPD_PASSWD}"
  echo "Use PureDB authentication method"
fi

# Check TLS cert
if [ -f "$PFTPD_PEM" ]; then
  chmod 600 "$PFTPD_PEM"
fi

echo "Flags"
echo "  Secure:$SECURE_FLAGS"
echo "  Additional:$ADD_FLAGS"
echo "  All:$FLAGS"

export PUREFTPD_FLAGS="$FLAGS"
exec "$@"
