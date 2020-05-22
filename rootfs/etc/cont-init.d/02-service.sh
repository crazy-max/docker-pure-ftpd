#!/usr/bin/with-contenv sh

mkdir -p /etc/services.d/pure-ftpd

cat > /etc/services.d/pure-ftpd/run <<EOL
#!/usr/bin/execlineb -P
with-contenv
pure-ftpd ${PUREFTPD_FLAGS}
EOL
chmod +x /etc/services.d/pure-ftpd/run

cat > /etc/services.d/pure-ftpd/finish <<EOL
#!/usr/bin/execlineb -S1
if { s6-test ${1} -ne 0 }
if { s6-test ${1} -ne 256 }
s6-svscanctl -t /var/run/s6/services
EOL
chmod +x /etc/services.d/pure-ftpd/finish