#!/bin/bash
# AMP Automated Backup Script
# Place in: /home/amp/scripts/auto_backup.sh
# Make executable: chmod +x /home/amp/scripts/auto_backup.sh

# Configuration
BACKUP_DIR="/opt/cubecoders/amp/backups"
LOG_FILE="/var/log/amp_backup.log"
RETENTION_DAYS=30
DISCORD_WEBHOOK_URL=""  # Optional: Add your Discord webhook URL for notifications

# Create log directory if it doesn't exist
sudo mkdir -p "$(dirname "$LOG_FILE")"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a "$LOG_FILE"
}

# Function to send Discord notification (optional)
send_discord_notification() {
    if [ -n "$DISCORD_WEBHOOK_URL" ]; then
        curl -H "Content-Type: application/json" \
             -X POST \
             -d "{\"content\":\"🔄 AMP Backup: $1\"}" \
             "$DISCORD_WEBHOOK_URL" 2>/dev/null
    fi
}

# Function to cleanup old backups
cleanup_old_backups() {
    log_message "Cleaning up backups older than $RETENTION_DAYS days"
    find "$BACKUP_DIR" -name "*.zip" -type f -mtime +$RETENTION_DAYS -delete
    log_message "Cleanup completed"
}

# Function to check disk space
check_disk_space() {
    local available_space=$(df "$BACKUP_DIR" | awk 'NR==2 {print $4}')
    local required_space=1048576  # 1GB in KB
    
    if [ "$available_space" -lt "$required_space" ]; then
        log_message "WARNING: Low disk space available for backups"
        send_discord_notification "⚠️ Low disk space for AMP backups!"
        return 1
    fi
    return 0
}

# Function to backup all instances
backup_all_instances() {
    log_message "Starting automated backup of all AMP instances"
    send_discord_notification "Starting automated backup"
    
    # Check disk space before starting
    if ! check_disk_space; then
        log_message "ERROR: Insufficient disk space for backup"
        send_discord_notification "❌ Backup failed: Insufficient disk space"
        exit 1
    fi
    
    # Switch to AMP user and perform backup
    su -l amp -c "
        ampinstmgr backupall
    "
    
    if [ $? -eq 0 ]; then
        log_message "Backup completed successfully"
        send_discord_notification "✅ AMP backup completed successfully"
    else
        log_message "ERROR: Backup failed"
        send_discord_notification "❌ AMP backup failed"
        exit 1
    fi
}

# Function to backup specific instance
backup_specific_instance() {
    local instance_name="$1"
    
    if [ -z "$instance_name" ]; then
        log_message "ERROR: No instance name provided"
        exit 1
    fi
    
    log_message "Starting backup of instance: $instance_name"
    send_discord_notification "Starting backup of $instance_name"
    
    # Check if instance exists
    if ! su -l amp -c "ampinstmgr list" | grep -q "$instance_name"; then
        log_message "ERROR: Instance $instance_name not found"
        send_discord_notification "❌ Instance $instance_name not found"
        exit 1
    fi
    
    # Perform backup
    su -l amp -c "
        ampinstmgr backup $instance_name
    "
    
    if [ $? -eq 0 ]; then
        log_message "Backup of $instance_name completed successfully"
        send_discord_notification "✅ Backup of $instance_name completed"
    else
        log_message "ERROR: Backup of $instance_name failed"
        send_discord_notification "❌ Backup of $instance_name failed"
        exit 1
    fi
}

# Function to show backup status
show_backup_status() {
    echo "=== AMP Backup Status ==="
    echo "Backup Directory: $BACKUP_DIR"
    echo "Available Space: $(df -h "$BACKUP_DIR" | awk 'NR==2 {print $4}')"
    echo "Recent Backups:"
    find "$BACKUP_DIR" -name "*.zip" -type f -mtime -7 -exec ls -lh {} \; | sort -k 6,7
    echo ""
    echo "Instance List:"
    su -l amp -c "ampinstmgr list"
}

# Main script logic
case "$1" in
    "all")
        backup_all_instances
        cleanup_old_backups
        ;;
    "cleanup")
        cleanup_old_backups
        ;;
    "status")
        show_backup_status
        ;;
    "")
        backup_all_instances
        cleanup_old_backups
        ;;
    *)
        backup_specific_instance "$1"
        ;;
esac

log_message "Backup script completed"
