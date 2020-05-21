#!/usr/bin/with-contenv sh

#UPLOADSCRIPT=${UPLOADSCRIPT:-/data/uploadscript.sh}

if [ -z "$UPLOADSCRIPT" ]; then
  exit 0
fi
if [ ! -f "$UPLOADSCRIPT" ]; then
  >&2 echo "ERROR: UPLOADSCRIPT program/script is not defined or does not exist"
  exit 1
fi

mkdir -p /etc/services.d/pure-uploadscript
cat > /etc/services.d/pure-uploadscript/run <<EOL
#!/usr/bin/execlineb -P
with-contenv
pure-uploadscript --daemon --run ${UPLOADSCRIPT}
EOL
chmod +x /etc/services.d/pure-uploadscript/run
