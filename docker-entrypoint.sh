#!/bin/bash
set -e

echo "=== TauCetiClassic Docker Entrypoint ==="

CONFIG_DIR="config"

# Copy example configs if not present
for f in "$CONFIG_DIR/example/"*; do
    fname=$(basename "$f")
    if [ -d "$f" ]; then
        [ ! -d "$CONFIG_DIR/$fname" ] && cp -r "$f" "$CONFIG_DIR/$fname" && echo "Copied dir: $fname"
        continue
    fi
    [ ! -f "$CONFIG_DIR/$fname" ] && cp "$f" "$CONFIG_DIR/$fname" && echo "Copied: $fname"
done

# Generate dbconfig.txt from env
cat > "$CONFIG_DIR/dbconfig.txt" <<EOF
ADDRESS ${SS13_DB_ADDRESS:-db}
PORT ${SS13_DB_PORT:-3306}
DATABASE ${MYSQL_DATABASE:-ss13}
LOGIN ${MYSQL_USER:-ss13}
PASSWORD ${MYSQL_PASSWORD:-changeme}
EOF
echo "Generated dbconfig.txt"

# Patch config.txt
if [ -f "$CONFIG_DIR/config.txt" ]; then
    sed -i 's/^# SQL_ENABLED/SQL_ENABLED/' "$CONFIG_DIR/config.txt"
    sed -i 's/^#SQL_ENABLED/SQL_ENABLED/' "$CONFIG_DIR/config.txt"
    grep -q '^SQL_ENABLED' "$CONFIG_DIR/config.txt" || echo "SQL_ENABLED" >> "$CONFIG_DIR/config.txt"

    if [ -n "$SS13_SERVERNAME" ]; then
        if grep -q '# SERVERNAME' "$CONFIG_DIR/config.txt"; then
            sed -i "s/^# SERVERNAME.*/SERVERNAME ${SS13_SERVERNAME}/" "$CONFIG_DIR/config.txt"
        elif ! grep -q '^SERVERNAME' "$CONFIG_DIR/config.txt"; then
            echo "SERVERNAME ${SS13_SERVERNAME}" >> "$CONFIG_DIR/config.txt"
        fi
    fi
    echo "Patched config.txt"
fi

# Wait for database
echo "Waiting for database at ${SS13_DB_ADDRESS:-db}:${SS13_DB_PORT:-3306}..."
for i in $(seq 1 30); do
    if bash -c "echo > /dev/tcp/${SS13_DB_ADDRESS:-db}/${SS13_DB_PORT:-3306}" 2>/dev/null; then
        echo "Database is ready!"
        break
    fi
    [ "$i" -eq 30 ] && echo "WARNING: Database not reachable after 30s, starting anyway..."
    sleep 1
done

# Start DreamDaemon
source /opt/byond/byond/bin/byondsetup
echo "Starting DreamDaemon on port ${SS13_PORT:-1488}..."
exec DreamDaemon taucetistation.dmb "${SS13_PORT:-1488}" -invisible -trusted -core
