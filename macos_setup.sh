#!/bin/bash

# Log Tail Agent Setup for macOS
# Uses launchd instead of systemd

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# Deploy agent on macOS
deploy_macos() {
    print_header "Deploying Log Tail Agent on macOS"
    
    local install_dir="/usr/local/opt/log-tail-agent"
    
    read -p "Installation directory [$install_dir]: " user_install_dir
    install_dir=${user_install_dir:-$install_dir}
    
    print_status "Creating installation directory: $install_dir"
    sudo mkdir -p "$install_dir"
    
    # Copy files
    if [[ -f "log-tail-mysql.sh" ]]; then
        print_status "Installing tail agent script..."
        sudo cp log-tail-mysql.sh "$install_dir/"
        sudo chmod +x "$install_dir/log-tail-mysql.sh"
    else
        print_error "log-tail-mysql.sh not found in current directory"
        exit 1
    fi
    
    if [[ -f "log-tail.conf" ]]; then
        print_status "Installing configuration file..."
        sudo cp log-tail.conf "$install_dir/"
    else
        print_warning "log-tail.conf not found, creating template..."
        sudo tee "$install_dir/log-tail.conf" > /dev/null <<'EOF'
# MySQL Database Configuration
MYSQL_HOST="your-mysql-host.com"
MYSQL_PORT="3306"
MYSQL_USER="log_user"
MYSQL_PASS="your_secure_password"
MYSQL_DB="centralized_logs"
MYSQL_TABLE="error_logs"

# Server Configuration - CUSTOMIZE FOR THIS MAC
SERVER_NAME="CHANGE_ME_MAC"
LOG_FILE="/var/log/system.log"

# Performance Settings
BATCH_SIZE="50"
FLUSH_INTERVAL="60"

# Log Filtering
ERROR_PATTERN="ERROR|FATAL|CRITICAL"
EOF
    fi
    
    # Create launchd plist for macOS
    local plist_path="$HOME/Library/LaunchAgents/com.logtail.agent.plist"
    print_status "Creating launchd service: $plist_path"
    
    mkdir -p "$HOME/Library/LaunchAgents"
    
    cat > "$plist_path" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.logtail.agent</string>
    <key>ProgramArguments</key>
    <array>
        <string>$install_dir/log-tail-mysql.sh</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$install_dir</string>
    <key>KeepAlive</key>
    <true/>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/log-tail-agent.out</string>
    <key>StandardErrorPath</key>
    <string>/tmp/log-tail-agent.err</string>
</dict>
</plist>
EOF
    
    print_status "Installation completed!"
    echo
    print_warning "macOS-specific next steps:"
    echo "1. Edit configuration: sudo vi $install_dir/log-tail.conf"
    echo "2. Test configuration: $install_dir/log-tail-mysql.sh --test"
    echo "3. Load service: launchctl load $plist_path"
    echo "4. Start service: launchctl start com.logtail.agent"
    echo "5. Check if running: launchctl list | grep logtail"
    echo "6. View logs: tail -f /tmp/log-tail-agent.out"
}

# Configure the agent
configure_macos() {
    print_header "Configure Log Tail Agent"
    
    local config_file="/usr/local/opt/log-tail-agent/log-tail.conf"
    
    if [[ ! -f "$config_file" ]]; then
        print_error "Agent not deployed yet. Run '$0 deploy' first."
        exit 1
    fi
    
    read -p "MySQL Host: " mysql_host
    read -p "MySQL Port [3306]: " mysql_port
    mysql_port=${mysql_port:-3306}
    read -p "MySQL Database: " mysql_db
    read -p "MySQL Table [error_logs]: " mysql_table
    mysql_table=${mysql_table:-error_logs}
    read -p "MySQL Username: " mysql_user
    read -s -p "MySQL Password: " mysql_pass
    echo
    read -p "Server Name (unique) [$(hostname)]: " server_name
    server_name=${server_name:-$(hostname)}
    read -p "Log File Path [/var/log/system.log]: " log_file
    log_file=${log_file:-"/var/log/system.log"}
    read -p "Batch Size [50]: " batch_size
    batch_size=${batch_size:-50}
    read -p "Flush Interval [60]: " flush_interval
    flush_interval=${flush_interval:-60}
    
    print_status "Updating configuration..."
    sudo tee "$config_file" > /dev/null <<EOF
# MySQL Database Configuration
MYSQL_HOST="$mysql_host"
MYSQL_PORT="$mysql_port"
MYSQL_USER="$mysql_user"
MYSQL_PASS="$mysql_pass"
MYSQL_DB="$mysql_db"
MYSQL_TABLE="$mysql_table"

# Server Configuration
SERVER_NAME="$server_name"
LOG_FILE="$log_file"

# Performance Settings
BATCH_SIZE="$batch_size"
FLUSH_INTERVAL="$flush_interval"

# Log Filtering
ERROR_PATTERN="ERROR|FATAL|CRITICAL"
EOF
    
    print_status "Configuration updated!"
    
    # Test configuration
    if /usr/local/opt/log-tail-agent/log-tail-mysql.sh --test; then
        print_status "Configuration test passed!"
    else
        print_error "Configuration test failed!"
    fi
}

# Show status
show_status() {
    print_header "Log Tail Agent Status"
    
    if launchctl list | grep -q com.logtail.agent; then
        print_status "Service is loaded in launchd"
        launchctl list com.logtail.agent 2>/dev/null || true
    else
        print_warning "Service not loaded in launchd"
    fi
    
    echo
    echo "Recent output logs:"
    tail -20 /tmp/log-tail-agent.out 2>/dev/null || echo "No output logs found"
    
    echo
    echo "Recent error logs:"
    tail -20 /tmp/log-tail-agent.err 2>/dev/null || echo "No error logs found"
}

# Test configuration
test_config() {
    print_header "Test Configuration"
    
    local script_path="/usr/local/opt/log-tail-agent/log-tail-mysql.sh"
    if [[ ! -f "$script_path" ]]; then
        print_error "Agent not installed. Run '$0 deploy' first."
        exit 1
    fi
    
    "$script_path" --test
}

# Start/stop service
manage_service() {
    local action="$1"
    local plist_path="$HOME/Library/LaunchAgents/com.logtail.agent.plist"
    
    case "$action" in
        start)
            print_status "Starting log tail agent..."
            launchctl load "$plist_path" 2>/dev/null || true
            launchctl start com.logtail.agent
            ;;
        stop)
            print_status "Stopping log tail agent..."
            launchctl stop com.logtail.agent
            launchctl unload "$plist_path" 2>/dev/null || true
            ;;
        restart)
            manage_service stop
            sleep 2
            manage_service start
            ;;
        *)
            print_error "Unknown service action: $action"
            exit 1
            ;;
    esac
}

# Show macOS-specific help
show_macos_help() {
    cat <<EOF
Log Tail Agent Setup for macOS

Usage: $0 <command>

Commands:
  deploy      - Install agent on macOS (uses launchd)
  configure   - Setup configuration interactively
  test        - Test MySQL connection
  start       - Start the agent service
  stop        - Stop the agent service
  restart     - Restart the agent service
  status      - Show service status and logs
  uninstall   - Remove agent from macOS

macOS Service Management:
  launchctl load ~/Library/LaunchAgents/com.logtail.agent.plist
  launchctl start com.logtail.agent
  launchctl stop com.logtail.agent
  launchctl unload ~/Library/LaunchAgents/com.logtail.agent.plist

Logs Location:
  Output: /tmp/log-tail-agent.out
  Errors: /tmp/log-tail-agent.err

Common macOS Log Files:
  System: /var/log/system.log
  Application: ~/Library/Logs/YourApp/app.log
  Web Server: /usr/local/var/log/nginx/error.log

EOF
}

# Uninstall
uninstall_macos() {
    print_header "Uninstall Log Tail Agent"
    
    read -p "Remove log tail agent from macOS? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Cancelled."
        exit 0
    fi
    
    # Stop service
    launchctl stop com.logtail.agent 2>/dev/null || true
    launchctl unload "$HOME/Library/LaunchAgents/com.logtail.agent.plist" 2>/dev/null || true
    
    # Remove files
    rm -f "$HOME/Library/LaunchAgents/com.logtail.agent.plist"
    sudo rm -rf /usr/local/opt/log-tail-agent
    rm -f /tmp/log-tail-agent.out /tmp/log-tail-agent.err
    
    print_status "Uninstall completed!"
}

# Main execution
case "${1:-}" in
    deploy)
        deploy_macos
        ;;
    configure)
        configure_macos
        ;;
    test)
        test_config
        ;;
    start)
        manage_service start
        ;;
    stop)
        manage_service stop
        ;;
    restart)
        manage_service restart
        ;;
    status)
        show_status
        ;;
    uninstall)
        uninstall_macos
        ;;
    help|--help|-h|"")
        show_macos_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_macos_help
        exit 1
        ;;
esac