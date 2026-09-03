#!/bin/bash

BACKUP_DIR="/backup"
DATE=$(date +%Y%m%d_%H%M%S)

mariadb-dump inventory > "$BACKUP_DIR/inventory_$DATE.sql"
find "$BACKUP_DIR" -type f -name "inventory_*.sql" -mtime +7 -delete