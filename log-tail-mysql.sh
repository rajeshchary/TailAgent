#!/bin/bash

# Log Tail Agent - Push ERROR logs to Central MySQL
# Lightweight agent for existing MySQL database setup
# Version: 1.0

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/log-tail.conf"

# Check if config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Source configuration
source "$CONFIG_FILE"

# Validate required variables
required_vars=("MYSQL_HOST" "MYSQL_PORT" "MYSQL_USER" "MYSQL_PASS" "MYSQL_DB" "MYSQL_TABLE" "LOG_FILE" "SERVER_NAME" "BATCH_SIZE" "FLUSH_INTERVAL")
for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
        echo "Error: $var is not set in configuration file"
        exit 1
    fi
done

# Global variables
TEMP_FILE="/tmp/error_logs_${SERVER_NAME}_$$.tmp"
PID_FILE="/var/run/log-tail-agent.pid"
LOG_BUFFER=()
BUFFER_COUNT=0
LAST_FLUSH=$(date +%s)

# Cleanup function
cleanup() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Shutting down log tail agent..."
    [[ -f "$TEMP_FILE" ]] && rm -f "$TEMP_FILE"
    [[ -f "$PID_FILE" ]] && rm -f "$PID_FILE"
    
    # Flush remaining buffer before exit
    if [[ ${#LOG_BUFFER[@]} -gt 0 ]]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Flushing final ${#LOG_BUFFER[@]} records..."
        flush_buffer
    fi
    exit 0
}

# Signal handlers
trap cleanup SIGTERM SIGINT EXIT

# Function to check MySQL connection
check_mysql_connection() {
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" -e "SELECT 1;" "$MYSQL_DB" &>/dev/null
    return $?
}

# Function to flush buffer to MySQL
flush_buffer() {
    if [[ ${#LOG_BUFFER[@]} -eq 0 ]]; then
        return 0
    fi
    
    # Create temporary SQL file for batch insert
    cat > "$TEMP_FILE" <<EOF
INSERT INTO $MYSQL_TABLE (server_name, timestamp, log_level, message) VALUES
EOF
    
    local first=true
    for entry in "${LOG_BUFFER[@]}"; do
        if [[ "$first" == "true" ]]; then
            first=false
        else
            echo "," >> "$TEMP_FILE"
        fi
        echo -n "$entry" >> "$TEMP_FILE"
    done
    echo ";" >> "$TEMP_FILE"
    
    # Execute batch insert with retry logic
    local retry_count=0
    local max_retries=3
    
    while [[ $retry_count -lt $max_retries ]]; do
        if mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" < "$TEMP_FILE" 2>/dev/null; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Flushed ${#LOG_BUFFER[@]} records to MySQL"
            LOG_BUFFER=()
            BUFFER_COUNT=0
            LAST_FLUSH=$(date +%s)
            rm -f "$TEMP_FILE"
            return 0
        else
            ((retry_count++))
            echo "$(date '+%Y-%m-%d %H:%M:%S') - MySQL insert failed, retry $retry_count/$max_retries"
            sleep $((retry_count * 2))  # Exponential backoff
        fi
    done
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Failed to flush buffer after $max_retries retries"
    return 1
}

# Function to parse and add log entry to buffer
add_to_buffer() {
    local log_line="$1"
    local current_time=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Extract timestamp from log line (customize based on your log format)
    local log_timestamp=""
    if [[ "$log_line" =~ ([0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]]+[0-9]{2}:[0-9]{2}:[0-9]{2}) ]]; then
        log_timestamp="${BASH_REMATCH[1]}"
    elif [[ "$log_line" =~ ([0-9]{2}/[0-9]{2}/[0-9]{4}[[:space:]]+[0-9]{2}:[0-9]{2}:[0-9]{2}) ]]; then
        # Handle MM/DD/YYYY format
        log_timestamp="${BASH_REMATCH[1]}"
        # Convert to MySQL format if needed
        log_timestamp=$(date -d "$log_timestamp" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "$current_time")
    else
        log_timestamp="$current_time"
    fi
    
    # Extract log level (ERROR, FATAL, etc.)
    local log_level="ERROR"
    if [[ "$log_line" =~ (ERROR|FATAL|CRITICAL|WARN|WARNING) ]]; then
        log_level="${BASH_REMATCH[1]}"
    fi
    
    # Escape special characters for MySQL
    local escaped_message=$(printf '%s\n' "$log_line" | sed "s/'/\\\\'/g" | sed 's/\\/\\\\/g')
    
    # Truncate very long messages to prevent memory issues
    if [[ ${#escaped_message} -gt 10000 ]]; then
        escaped_message="${escaped_message:0:10000}... [TRUNCATED]"
    fi
    
    # Add to buffer
    local sql_values="('$SERVER_NAME', '$log_timestamp', '$log_level', '$escaped_message')"
    LOG_BUFFER+=("$sql_values")
    ((BUFFER_COUNT++))
}

# Function to check if flush is needed
should_flush() {
    local current_time=$(date +%s)
    local time_diff=$((current_time - LAST_FLUSH))
    
    if [[ $BUFFER_COUNT -ge $BATCH_SIZE ]] || [[ $time_diff -ge $FLUSH_INTERVAL ]]; then
        return 0
    else
        return 1
    fi
}

# Function to monitor log file and process entries
monitor_logs() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting log monitoring..."
    echo "  Log file: $LOG_FILE"
    echo "  Server: $SERVER_NAME"
    echo "  Pattern: $ERROR_PATTERN"
    echo "  Batch size: $BATCH_SIZE"
    echo "  Flush interval: ${FLUSH_INTERVAL}s"
    
    # Check if log file exists, if not wait for it
    while [[ ! -f "$LOG_FILE" ]]; do
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Waiting for log file: $LOG_FILE"
        sleep 10
    done
    
    # Start tailing with error handling
    tail -F "$LOG_FILE" 2>/dev/null | while IFS= read -r line; do
        # Filter for ERROR lines (case insensitive)
        if echo "$line" | grep -Eqi "$ERROR_PATTERN"; then
            add_to_buffer "$line"
            
            # Check if we need to flush
            if should_flush; then
                if ! flush_buffer; then
                    echo "$(date '+%Y-%m-%d %H:%M:%S') - Warning: Flush failed, continuing..."
                fi
            fi
        fi
    done &
    
    local tail_pid=$!
    
    # Background process for periodic flushing
    while true; do
        sleep "$FLUSH_INTERVAL"
        if [[ ${#LOG_BUFFER[@]} -gt 0 ]]; then
            if ! flush_buffer; then
                echo "$(date '+%Y-%m-%d %H:%M:%S') - Warning: Periodic flush failed"
            fi
        fi
        
        # Check if tail process is still running
        if ! kill -0 $tail_pid 2>/dev/null; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Tail process died, restarting..."
            monitor_logs  # Restart monitoring
            break
        fi
    done
}

# Main function
main() {
    # Check if already running
    if [[ -f "$PID_FILE" ]]; then
        local old_pid=$(cat "$PID_FILE")
        if kill -0 "$old_pid" 2>/dev/null; then
            echo "Log tail agent is already running with PID: $old_pid"
            exit 1
        else
            rm -f "$PID_FILE"
        fi
    fi
    
    # Write PID file
    echo $$ > "$PID_FILE"
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting Log Tail Agent for $SERVER_NAME"
    
    # Check MySQL connection
    if ! check_mysql_connection; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Cannot connect to MySQL database"
        echo "  Host: $MYSQL_HOST:$MYSQL_PORT"
        echo "  Database: $MYSQL_DB"
        echo "  User: $MYSQL_USER"
        exit 1
    fi
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - MySQL connection verified"
    
    # Start monitoring
    monitor_logs
}

# Help function
show_help() {
    cat <<EOF
Usage: $0 [OPTIONS]

Log Tail Agent - Push ERROR logs to Central MySQL

Options:
    -h, --help      Show this help message
    -c, --config    Specify config file path (default: ./log-tail.conf)
    -d, --daemon    Run as daemon
    -s, --stop      Stop running daemon
    -t, --test      Test MySQL connection and exit
    -v, --version   Show version

Examples:
    $0              Run in foreground
    $0 --test       Test configuration
    $0 --daemon     Run as background daemon
    $0 --stop       Stop daemon

Configuration file must contain:
    MYSQL_HOST, MYSQL_PORT, MYSQL_USER, MYSQL_PASS, MYSQL_DB, MYSQL_TABLE
    LOG_FILE, SERVER_NAME, BATCH_SIZE, FLUSH_INTERVAL, ERROR_PATTERN

EOF
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    -v|--version)
        echo "Log Tail Agent v1.0"
        exit 0
        ;;
    -t|--test)
        echo "Testing configuration..."
        source "$CONFIG_FILE" 2>/dev/null || { echo "Failed to load config"; exit 1; }
        echo "  Config file: OK"
        
        if [[ ! -f "$LOG_FILE" ]]; then
            echo "  Log file: NOT FOUND ($LOG_FILE)"
        else
            echo "  Log file: OK ($LOG_FILE)"
        fi
        
        echo "Testing MySQL connection..."
        if check_mysql_connection; then
            echo "  MySQL connection: OK"
            echo "  Host: $MYSQL_HOST:$MYSQL_PORT"
            echo "  Database: $MYSQL_DB"
            echo "  Table: $MYSQL_TABLE"
            exit 0
        else
            echo "  MySQL connection: FAILED"
            exit 1
        fi
        ;;
    -s|--stop)
        if [[ -f "$PID_FILE" ]]; then
            local pid=$(cat "$PID_FILE")
            if kill "$pid" 2>/dev/null; then
                echo "Stopped log tail agent (PID: $pid)"
                rm -f "$PID_FILE"
            else
                echo "Process $pid not found"
                rm -f "$PID_FILE"
            fi
        else
            echo "PID file not found - agent may not be running"
        fi
        exit 0
        ;;
    -d|--daemon)
        echo "Starting log tail agent as daemon..."
        nohup "$0" > /dev/null 2>&1 &
        echo "Started with PID: $!"
        exit 0
        ;;
    -c|--config)
        if [[ -z "$2" ]]; then
            echo "Error: --config requires a file path"
            exit 1
        fi
        CONFIG_FILE="$2"
        shift 2
        main "$@"
        ;;
    "")
        main
        ;;
    *)
        echo "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac