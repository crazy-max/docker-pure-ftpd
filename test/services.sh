#!/bin/sh
set -eu

s6-svwait -U -t 30000 /run/service/syslog
s6-svwait -u -t 30000 /run/service/pure-ftpd
test "$(s6-svstat -o up,wantedup /run/service/pure-ftpd)" = "true true"
test -S /dev/log

if [ -n "${UPLOADSCRIPT:-}" ]; then
  s6-svwait -u -t 30000 /run/service/pure-uploadscript
  test "$(s6-svstat -o up,wantedup /run/service/pure-uploadscript)" = "true true"
else
  test "$(s6-svstat -o up,wantedup /run/service/pure-uploadscript)" = "false false"
fi
