#!/bin/bash

# Log Tail Agent Deployment Script
# Deploys the tail agent to push logs to existing Central MySQL

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if MySQL client is installed
check_mysql_client() {
    if ! command -v mysql &> /dev/null; then
        print_error "MySQL client is not installed"
        echo "Please install MySQL client:"
        echo "  Ubuntu/Debian: sudo apt-get install mysql-client"
        echo "  CentOS/RHEL: sudo yum install mysql"
        echo "  Amazon Linux: sudo yum install mysql56"
        exit 1
    fi
    print_status "MySQL client found"
}

# Deploy the log tail agent
deploy_agent() {
    print_header "Deploying Log Tail Agent"
    
    local install_dir="/opt/log-tail-agent"
    
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
# MySQL Database Configuration (Existing Setup)
MYSQL_HOST="your-mysql-host.com"
MYSQL_PORT="3306"
MYSQL_USER="log_user"
MYSQL_PASS="your_secure_password"
MYSQL_DB="centralized_logs"
MYSQL_TABLE="error_logs"

# Server Configuration - CUSTOMIZE FOR THIS SERVER
SERVER_NAME="CHANGE_ME"
LOG_FILE="/var/log/application/app.log"

# Performance Settings
BATCH_SIZE="100"
FLUSH_INTERVAL="30"

# Log Filtering
ERROR_PATTERN="ERROR|FATAL|CRITICAL"
EOF
    fi
    
    # Create systemd service
    print_status "Creating systemd service..."
    sudo tee /etc/systemd/system/log-tail-agent.service > /dev/null <<EOF
[Unit]
Description=Log Tail Agent - Central MySQL Error Log Monitoring
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$install_dir
ExecStart=$install_dir/log-tail-mysql.sh
ExecStop=$install_dir/log-tail-mysql.sh --stop
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    sudo systemctl daemon-reload
    
    print_status "Installation completed!"
    echo
    print_warning "NEXT STEPS:"
    echo "1. Edit configuration: sudo vi $install_dir/log-tail.conf"
    echo "2. Test configuration: sudo $install_dir/log-tail-mysql.sh --test"
    echo "3. Start the agent: sudo systemctl start log-tail-agent"
    echo "4. Enable auto-start: sudo systemctl enable log-tail-agent"
    echo "5. Check status: sudo systemctl status log-tail-agent"
    echo "6. View logs: sudo journalctl -u log-tail-agent -f"
}

# Configure the agent interactively
configure_agent() {
    print_header "Configure Log Tail Agent"
    
    local config_file="/opt/log-tail-agent/log-tail.conf"
    
    if [[ ! -f "$config_file" ]]; then
        print_error "Agent not deployed yet. Run '$0 deploy' first."
        exit 1
    fi
    
    echo "Current configuration:"
    grep -E "^[A-Z_]+" "$config_file" | head -10
    echo
    
    read -p "MySQL Host: " mysql_host
    read -p "MySQL Port [3306]: " mysql_port
    mysql_port=${mysql_port:-3306}
    read -p "MySQL Database: " mysql_db
    read -p "MySQL Table [error_logs]: " mysql_table
    mysql_table=${mysql_table:-error_logs}
    read -p "MySQL Username: " mysql_user
    read -s -p "MySQL Password: " mysql_pass
    echo
    read -p "Server Name (unique): " server_name
    read -p "Log File Path: " log_file
    read -p "Batch Size [100]: " batch_size
    batch_size=${batch_size:-100}
    read -p "Flush Interval [30]: " flush_interval
    flush_interval=${flush_interval:-30}
    read -p "Error Pattern [ERROR|FATAL|CRITICAL]: " error_pattern
    error_pattern=${error_pattern:-"ERROR|FATAL|CRITICAL"}
    
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
ERROR_PATTERN="$error_pattern"
EOF
    
    print_status "Configuration updated successfully!"
    echo
    print_status "Testing configuration..."
    if sudo /opt/log-tail-agent/log-tail-mysql.sh --test; then
        print_status "Configuration test passed!"
    else
        print_error "Configuration test failed!"
        exit 1
    fi
}

# Show agent status
show_status() {
    print_header "Log Tail Agent Status"
    
    echo "Service Status:"
    if systemctl is-active --quiet log-tail-agent; then
        print_status "Service is running"
        systemctl status log-tail-agent --no-pager -l
    else
        print_warning "Service is not running"
        systemctl status log-tail-agent --no-pager -l || true
    fi
    
    echo
    echo "Recent logs:"
    sudo journalctl -u log-tail-agent -n 20 --no-pager
}

# Quick test function
quick_test() {
    print_header "Quick Test"
    
    if [[ ! -f "/opt/log-tail-agent/log-tail-mysql.sh" ]]; then
        print_error "Agent not installed. Run '$0 deploy' first."
        exit 1
    fi
    
    print_status "Testing MySQL connection..."
    sudo /opt/log-tail-agent/log-tail-mysql.sh --test
}

# Uninstall agent
uninstall_agent() {
    print_header "Uninstall Log Tail Agent"
    
    read -p "Are you sure you want to uninstall the log tail agent? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Cancelled."
        exit 0
    fi
    
    print_status "Stopping service..."
    sudo systemctl stop log-tail-agent 2>/dev/null || true
    sudo systemctl disable log-tail-agent 2>/dev/null || true
    
    print_status "Removing service file..."
    sudo rm -f /etc/systemd/system/log-tail-agent.service
    sudo systemctl daemon-reload
    
    print_status "Removing installation directory..."
    sudo rm -rf /opt/log-tail-agent
    
    print_status "Cleanup completed!"
}

# Multi-server deployment guide
deployment_guide() {
    print_header "Multi-Server Deployment Guide"
    
    cat <<'EOF'
Quick Multi-Server Deployment:

1. Prepare Files:
   - log-tail-mysql.sh (the agent script)
   - log-tail.conf (base configuration)
   - deploy.sh (this script)

2. For Each Server:
   
   a) Copy files to server:
   scp log-tail-mysql.sh log-tail.conf deploy.sh user@server:/tmp/
   
   b) SSH to server and deploy:
   ssh user@server
   cd /tmp
   chmod +x deploy.sh log-tail-mysql.sh
   sudo ./deploy.sh deploy
   
   c) Configure for this specific server:
   sudo ./deploy.sh configure
   # OR manually edit: sudo vi /opt/log-tail-agent/log-tail.conf
   
   d) Start monitoring:
   sudo systemctl start log-tail-agent
   sudo systemctl enable log-tail-agent

3. Verify Deployment:
   sudo ./deploy.sh status
   # OR check logs: sudo journalctl -u log-tail-agent -f

4. Server-Specific Settings:

   High Volume Web Server:
   - BATCH_SIZE="300"
   - FLUSH_INTERVAL="15"
   
   API Server:
   - BATCH_SIZE="150"  
   - FLUSH_INTERVAL="20"
   
   Background Worker:
   - BATCH_SIZE="50"
   - FLUSH_INTERVAL="60"

5. Monitor All Servers:
   SELECT server_name, COUNT(*) as error_count
   FROM error_logs 
   WHERE created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
   GROUP BY server_name;

EOF
}

# Show help
show_help() {
    cat <<EOF
Log Tail Agent Deployment Script

Usage: $0 <command>

Commands:
  deploy      - Deploy agent to this server
  configure   - Configure agent interactively
  status      - Show agent status and recent logs
  test        - Test MySQL connection
  uninstall   - Remove agent from this server
  guide       - Show multi-server deployment guide
  help        - Show this help

Examples:
  $0 deploy          # Deploy agent
  $0 configure       # Setup configuration
  $0 test           # Test configuration
  $0 status         # Check if running
  
Multi-server deployment:
  1. $0 deploy      # On each server
  2. $0 configure   # Customize each server
  3. Start service: sudo systemctl start log-tail-agent

EOF
}

# Main execution
main() {
    if [[ $# -eq 0 ]]; then
        show_help
        exit 1
    fi
    
    case "$1" in
        deploy)
            check_mysql_client
            deploy_agent
            ;;
        configure)
            configure_agent
            ;;
        status)
            show_status
            ;;
        test)
            quick_test
            ;;
        uninstall)
            uninstall_agent
            ;;
        guide)
            deployment_guide
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"