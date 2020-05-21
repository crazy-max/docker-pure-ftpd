#!/usr/bin/with-contenv sh

mkdir -p /etc/services.d/pure-ftpd
cat > /etc/services.d/pure-ftpd/run <<EOL
#!/usr/bin/execlineb -P
with-contenv
pure-ftpd ${PUREFTPD_FLAGS}
EOL
chmod +x /etc/services.d/pure-ftpd/run
