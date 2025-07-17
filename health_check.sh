#!/bin/bash
# AMP Health Check Script
# Place in: /home/amp/scripts/health_check.sh
# Make executable: chmod +x /home/amp/scripts/health_check.sh

# Configuration
LOG_FILE="/var/log/amp_health.log"
ALERT_EMAIL=""  # Optional: Add email for critical alerts
DISCORD_WEBHOOK_URL=""  # Optional: Add Discord webhook for notifications
CPU_THRESHOLD=80
MEMORY_THRESHOLD=80
DISK_THRESHOLD=90

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a "$LOG_FILE"
}

# Function to send alert
send_alert() {
    local message="$1"
    local severity="$2"
    
    log_message "ALERT [$severity]: $message"
    
    # Discord notification
    if [ -n "$DISCORD_WEBHOOK_URL" ]; then
        local emoji="⚠️"
        if [ "$severity" = "CRITICAL" ]; then
            emoji="🚨"
        elif [ "$severity" = "WARNING" ]; then
            emoji="⚠️"
        else
            emoji="ℹ️"
        fi
        
        curl -H "Content-Type: application/json" \
             -X POST \
             -d "{\"content\":\"$emoji **AMP Health Alert [$severity]**: $message\"}" \
             "$DISCORD_WEBHOOK_URL" 2>/dev/null
    fi
    
    # Email notification (requires mailutils)
    if [ -n "$ALERT_EMAIL" ] && command -v mail >/dev/null 2>&1; then
        echo "$message" | mail -s "AMP Health Alert [$severity]" "$ALERT_EMAIL"
    fi
}

# Function to check system resources
check_system_resources() {
    echo -e "${GREEN}=== System Resource Check ===${NC}"
    
    # CPU Usage
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    cpu_usage=${cpu_usage%.*}  # Remove decimal part
    
    if [ "$cpu_usage" -gt "$CPU_THRESHOLD" ]; then
        echo -e "${RED}❌ CPU Usage: ${cpu_usage}% (Threshold: ${CPU_THRESHOLD}%)${NC}"
        send_alert "High CPU usage detected: ${cpu_usage}%" "WARNING"
    else
        echo -e "${GREEN}✅ CPU Usage: ${cpu_usage}%${NC}"
    fi
    
    # Memory Usage
    local memory_info=$(free | grep Mem)
    local total_mem=$(echo $memory_info | awk '{print $2}')
    local used_mem=$(echo $memory_info | awk '{print $3}')
    local memory_usage=$((used_mem * 100 / total_mem))
    
    if [ "$memory_usage" -gt "$MEMORY_THRESHOLD" ]; then
        echo -e "${RED}❌ Memory Usage: ${memory_usage}% (Threshold: ${MEMORY_THRESHOLD}%)${NC}"
        send_alert "High memory usage detected: ${memory_usage}%" "WARNING"
    else
        echo -e "${GREEN}✅ Memory Usage: ${memory_usage}%${NC}"
    fi
    
    # Disk Usage
    local disk_usage=$(df /opt/cubecoders/amp | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [ "$disk_usage" -gt "$DISK_THRESHOLD" ]; then
        echo -e "${RED}❌ Disk Usage: ${disk_usage}% (Threshold: ${DISK_THRESHOLD}%)${NC}"
        send_alert "High disk usage detected: ${disk_usage}%" "CRITICAL"
    else
        echo -e "${GREEN}✅ Disk Usage: ${disk_usage}%${NC}"
    fi
}

# Function to check AMP service status
check_amp_service() {
    echo -e "${GREEN}=== AMP Service Check ===${NC}"
    
    # Check if ampinstmgr service is running
    if systemctl is-active --quiet ampinstmgr; then
        echo -e "${GREEN}✅ AMP Instance Manager service is running${NC}"
    else
        echo -e "${RED}❌ AMP Instance Manager service is not running${NC}"
        send_alert "AMP Instance Manager service is down" "CRITICAL"
        
        # Attempt to restart service
        echo "Attempting to restart AMP service..."
        sudo systemctl restart ampinstmgr
        sleep 5
        
        if systemctl is-active --quiet ampinstmgr; then
            echo -e "${GREEN}✅ AMP service restarted successfully${NC}"
            send_alert "AMP service was restarted successfully" "INFO"
        else
            echo -e "${RED}❌ Failed to restart AMP service${NC}"
            send_alert "Failed to restart AMP service" "CRITICAL"
        fi
    fi
}

# Function to check instance status
check_instance_status() {
    echo -e "${GREEN}=== Instance Status Check ===${NC}"
    
    # Get list of instances
    local instances=$(su -l amp -c "ampinstmgr list" 2>/dev/null)
    
    if [ -z "$instances" ]; then
        echo -e "${YELLOW}⚠️ No instances found or unable to retrieve instance list${NC}"
        return
    fi
    
    # Check each instance
    while IFS= read -r line; do
        if [[ $line =~ ^[[:space:]]*([^[:space:]]+)[[:space:]]+([^[:space:]]+)[[:space:]]+([^[:space:]]+) ]]; then
            local instance_name="${BASH_REMATCH[1]}"
            local status="${BASH_REMATCH[2]}"
            local module="${BASH_REMATCH[3]}"
            
            if [ "$status" = "Running" ]; then
                echo -e "${GREEN}✅ $instance_name ($module): $status${NC}"
            else
                echo -e "${RED}❌ $instance_name ($module): $status${NC}"
                send_alert "Instance $instance_name is $status" "WARNING"
            fi
        fi
    done <<< "$instances"
}

# Function to check port connectivity
check_port_connectivity() {
    echo -e "${GREEN}=== Port Connectivity Check ===${NC}"
    
    # Common AMP ports
    local ports=(8080 8081 8082)
    
    for port in "${ports[@]}"; do
        if netstat -tuln | grep -q ":$port "; then
            echo -e "${GREEN}✅ Port $port is listening${NC}"
        else
            echo -e "${YELLOW}⚠️ Port $port is not listening${NC}"
        fi
    done
}

# Function to check log files for errors
check_log_errors() {
    echo -e "${GREEN}=== Recent Log Errors Check ===${NC}"
    
    local log_dirs=(
        "/opt/cubecoders/amp/logs"
        "/opt/cubecoders/amp/instances"
    )
    
    local error_count=0
    
    for log_dir in "${log_dirs[@]}"; do
        if [ -d "$log_dir" ]; then
            # Check for errors in the last 24 hours
            local recent_errors=$(find "$log_dir" -name "*.log" -type f -mtime -1 -exec grep -l -i "error\|exception\|failed\|critical" {} \; 2>/dev/null | wc -l)
            
            if [ "$recent_errors" -gt 0 ]; then
                echo -e "${YELLOW}⚠️ Found $recent_errors log files with recent errors in $log_dir${NC}"
                error_count=$((error_count + recent_errors))
            fi
        fi
    done
    
    if [ "$error_count" -eq 0 ]; then
        echo -e "${GREEN}✅ No recent errors found in log files${NC}"
    else
        send_alert "Found $error_count log files with recent errors" "WARNING"
    fi
}

# Function to check backup status
check_backup_status() {
    echo -e "${GREEN}=== Backup Status Check ===${NC}"
    
    local backup_dir="/opt/cubecoders/amp/backups"
    
    if [ -d "$backup_dir" ]; then
        local recent_backups=$(find "$backup_dir" -name "*.zip" -type f -mtime -1 | wc -l)
        local total_backups=$(find "$backup_dir" -name "*.zip" -type f | wc -l)
        
        echo -e "${GREEN}✅ Recent backups (24h): $recent_backups${NC}"
        echo -e "${GREEN}✅ Total backups: $total_backups${NC}"
        
        if [ "$recent_backups" -eq 0 ]; then
            echo -e "${YELLOW}⚠️ No recent backups found${NC}"
            send_alert "No backups created in the last 24 hours" "WARNING"
        fi
    else
        echo -e "${RED}❌ Backup directory not found${NC}"
        send_alert "Backup directory not found" "WARNING"
    fi
}

# Function to generate summary report
generate_summary() {
    echo -e "${GREEN}=== Health Check Summary ===${NC}"
    echo "Health check completed at: $(date)"
    echo "System uptime: $(uptime -p)"
    echo "AMP installation: /opt/cubecoders/amp"
    echo "Log file: $LOG_FILE"
    echo ""
    echo "For detailed logs, run: tail -f $LOG_FILE"
}

# Main health check function
run_health_check() {
    log_message "Starting AMP health check"
    
    check_system_resources
    echo ""
    check_amp_service
    echo ""
    check_instance_status
    echo ""
    check_port_connectivity
    echo ""
    check_log_errors
    echo ""
    check_backup_status
    echo ""
    generate_summary
    
    log_message "Health check completed"
}

# Script execution
case "$1" in
    "system")
        check_system_resources
        ;;
    "service")
        check_amp_service
        ;;
    "instances")
        check_instance_status
        ;;
    "ports")
        check_port_connectivity
        ;;
    "logs")
        check_log_errors
        ;;
    "backups")
        check_backup_status
        ;;
    "summary")
        generate_summary
        ;;
    *)
        run_health_check
        ;;
esac
