#!/bin/bash
source ../lib/ui.sh

BACKUP_DIR="/root/tch-backups"
mkdir -p $BACKUP_DIR

auto_backup() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$BACKUP_DIR/backup_$timestamp.tar.gz"
    
    progress_bar 5 "Creating backup..."
    
    tar -czf $backup_file \
        /etc/nginx \
        /etc/mysql \
        /var/www \
        /etc/pterodactyl \
        2>/dev/null
    
    if [ $? -eq 0 ]; then
        local size=$(du -h $backup_file | cut -f1)
        status_indicator "success" "Backup created: $backup_file ($size)"
        
        # Auto-cleanup old backups (keep last 7)
        ls -t $BACKUP_DIR/backup_*.tar.gz | tail -n +8 | xargs rm -f 2>/dev/null
        status_indicator "info" "Old backups cleaned (keeping last 7)"
    else
        status_indicator "error" "Backup failed"
    fi
}

auto_backup
