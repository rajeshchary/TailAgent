# Log Tail Agent - Central MySQL Error Log Monitoring

A lightweight, efficient bash agent for monitoring application ERROR logs and pushing them to your existing central MySQL database. Designed for minimal CPU/IO impact across multiple EC2 servers.

## Features

- **Minimal Resource Usage**: Efficient batch processing and filtering
- **Real-time Monitoring**: Uses `tail -F` for immediate error detection  
- **Existing MySQL Integration**: Works with your current database setup
- **Multi-server Ready**: Easy deployment across multiple EC2 instances
- **Configurable Filtering**: Custom error patterns per server
- **Auto-recovery**: Handles log rotation and network issues
- **Service Integration**: Full systemd support

## Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   EC2-01    │    │   EC2-02    │    │   EC2-03    │
│             │    │             │    │             │
│ App Logs    │    │ App Logs    │    │ App Logs    │
│     ↓       │    │     ↓       │    │     ↓       │
│ Tail Agent  │    │ Tail Agent  │    │ Tail Agent  │
└──────┬──────┘    └──────┬──────┘    └──────┬──────┘
       │                  │                  │
       └──────────────────┼──────────────────┘
                          │
                   ┌──────▼──────┐
                   │  Existing   │
                   │   MySQL     │
                   │  Database   │
                   └─────────────┘
```

## Prerequisites

- Central MySQL database already setup
- Target table exists (see expected schema below)
- MySQL user with INSERT permissions
- MySQL client installed on each EC2 server

## Expected Database Schema

Your existing MySQL table should have this structure:

```sql
-- Your existing table should look like this:
CREATE TABLE error_logs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    server_name VARCHAR(255) NOT NULL,
    timestamp DATETIME NOT NULL,
    log_level VARCHAR(20) NOT NULL, 
    message TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_server_timestamp (server_name, timestamp)
);
```

## Quick Start

### 1. Deploy Agent on Each Server

```bash
# Copy files to your EC2 server
scp log-tail-mysql.sh log-tail.conf deploy.sh user@ec2-server:/tmp/

# SSH to server and deploy
ssh user@ec2-server
cd /tmp
chmod +x deploy.sh log-tail-mysql.sh
sudo ./deploy.sh deploy
```

### 2. Configure for Each Server

```bash
# Interactive configuration
sudo ./deploy.sh configure

# OR manually edit
sudo vi /opt/log-tail-agent/log-tail.conf
```

**Key settings to customize per server:**
- `SERVER_NAME`: Unique identifier (e.g., "prod-web-01")
- `LOG_FILE`: Path to your application log
- `BATCH_SIZE`: Adjust for log volume
- `FLUSH_INTERVAL`: How often to push to MySQL

### 3. Test and Start

```bash
# Test MySQL connection
sudo ./deploy.sh test

# Start the agent
sudo systemctl start log-tail-agent
sudo systemctl enable log-tail-agent

# Check status
sudo ./deploy.sh status
```

## Configuration Reference

### Basic Configuration (`log-tail.conf`)

```bash
# MySQL Connection (Your Existing Database)
MYSQL_HOST="your-mysql-host.com"
MYSQL_PORT="3306"
MYSQL_USER="log_user"
MYSQL_PASS="your_password"  
MYSQL_DB="your_database"
MYSQL_TABLE="error_logs"

# Server Settings
SERVER_NAME="web-server-01"              # UNIQUE per server
LOG_FILE="/var/log/application/app.log"  # Your app log path

# Performance Tuning
BATCH_SIZE="100"                         # Records per batch
FLUSH_INTERVAL="30"                      # Max seconds before flush

# Filtering
ERROR_PATTERN="ERROR|FATAL|CRITICAL"     # What to capture
```

### Performance Guidelines by Server Type

| Server Type | Log Volume | BATCH_SIZE | FLUSH_INTERVAL | Notes |
|-------------|------------|------------|----------------|-------|
| **High Volume Web** | 1000+/hour | 300-500 | 10-15s | Peak traffic handling |
| **API Server** | 100-500/hour | 150-200 | 20-30s | Balanced performance |
| **Background Worker** | <100/hour | 50-100 | 45-60s | Low resource usage |
| **Dev/Test** | <50/hour | 25-50 | 60-120s | Minimal impact |

### Server-Specific Examples

**Production Web Server:**
```bash
SERVER_NAME="prod-web-01"
LOG_FILE="/opt/webapp/logs/application.log"
BATCH_SIZE="300"
FLUSH_INTERVAL="15"
ERROR_PATTERN="ERROR|FATAL|CRITICAL|Exception"
```

**API Server:**
```bash
SERVER_NAME="api-server-02"  
LOG_FILE="/var/log/api/api.log"
BATCH_SIZE="150"
FLUSH_INTERVAL="20"
ERROR_PATTERN="ERROR|FATAL|HTTP 5[0-9][0-9]"
```

**Background Worker:**
```bash
SERVER_NAME="worker-01"
LOG_FILE="/var/log/worker/worker.log"
BATCH_SIZE="50"
FLUSH_INTERVAL="60"
ERROR_PATTERN="ERROR|FAILED|Exception"
```

## Usage Examples

### Command Line Operations

```bash
# Test configuration
sudo /opt/log-tail-agent/log-tail-mysql.sh --test

# Run in foreground (testing)
sudo /opt/log-tail-agent/log-tail-mysql.sh

# Run as daemon
sudo /opt/log-tail-agent/log-tail-mysql.sh --daemon

# Stop daemon
sudo /opt/log-tail-agent/log-tail-mysql.sh --stop
```

### Service Management

```bash
# Service operations
sudo systemctl start log-tail-agent
sudo systemctl stop log-tail-agent  
sudo systemctl restart log-tail-agent
sudo systemctl status log-tail-agent

# Enable auto-start
sudo systemctl enable log-tail-agent

# View real-time logs
sudo journalctl -u log-tail-agent -f
```

### Deployment Management

```bash
# Deploy to server
./deploy.sh deploy

# Configure interactively
./deploy.sh configure

# Check status
./deploy.sh status

# Test connection
./deploy.sh test

# Remove agent
./deploy.sh uninstall
```

## Querying Your Centralized Logs

```sql
-- Recent errors across all servers
SELECT server_name, timestamp, log_level, message 
FROM error_logs 
ORDER BY created_at DESC 
LIMIT 100;

-- Error count by server (last 24 hours)  
SELECT server_name, COUNT(*) as error_count
FROM error_logs 
WHERE created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
GROUP BY server_name
ORDER BY error_count DESC;

-- Critical errors only
SELECT * FROM error_logs 
WHERE log_level IN ('FATAL', 'CRITICAL')
ORDER BY created_at DESC;

-- Errors from specific server
SELECT * FROM error_logs 
WHERE server_name = 'prod-web-01'
AND created_at >= DATE_SUB(NOW(), INTERVAL 1 HOUR)
ORDER BY created_at DESC;

-- Hourly error trend
SELECT 
    server_name,
    DATE_FORMAT(created_at, '%Y-%m-%d %H:00') as hour,
    COUNT(*) as error_count
FROM error_logs 
WHERE created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
GROUP BY server_name, hour
ORDER BY hour DESC, error_count DESC;
```

## Multi-Server Deployment

### Automated Deployment Script

```bash
#!/bin/bash
# deploy-all-servers.sh

SERVERS=("web-01.example.com" "api-01.example.com" "worker-01.example.com")
USER="ec2-user"

for server in "${SERVERS[@]}"; do
    echo "Deploying to $server..."
    
    # Copy files
    scp log-tail-mysql.sh log-tail.conf deploy.sh $USER@$server:/tmp/
    
    # Deploy and start
    ssh $USER@$server '
        cd /tmp
        chmod +x deploy.sh log-tail-mysql.sh
        sudo ./deploy.sh deploy
        sudo systemctl start log-tail-agent
        sudo systemctl enable log-tail-agent
    '
done
```

### Configuration Templates

Create server-specific configs:

```bash
# web-server.conf
SERVER_NAME="prod-web-01"
BATCH_SIZE="300"
FLUSH_INTERVAL="15"

# api-server.conf  
SERVER_NAME="api-server-01"
BATCH_SIZE="150"
FLUSH_INTERVAL="20"

# worker.conf
SERVER_NAME="worker-01" 
BATCH_SIZE="50"
FLUSH_INTERVAL="60"
```

## Monitoring and Maintenance

### Health Check Script

```bash
#!/bin/bash
# health-check.sh - Run on each server

if systemctl is-active --quiet log-tail-agent; then
    echo "✓ Service running"
else
    echo "✗ Service not running"
    exit 1
fi

# Test MySQL connection
if /opt/log-tail-agent/log-tail-mysql.sh --test; then
    echo "✓ MySQL connection OK"
else
    echo "✗ MySQL connection failed"
    exit 1
fi
```

### Database Maintenance

```sql
-- Archive old logs (keep last 30 days)
DELETE FROM error_logs 
WHERE created_at < DATE_SUB(NOW(), INTERVAL 30 DAY);

-- Check table size
SELECT 
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Size (MB)'
FROM information_schema.tables 
WHERE table_name = 'error_logs';

-- Monitor ingestion rate
SELECT 
    server_name,
    COUNT(*) as today_errors,
    MAX(created_at) as last_error
FROM error_logs 
WHERE DATE(created_at) = CURDATE()
GROUP BY server_name;
```

## Troubleshooting

### Common Issues

**1. Agent Won't Start**
```bash
# Check configuration
sudo /opt/log-tail-agent/log-tail-mysql.sh --test

# Check service logs
sudo journalctl -u log-tail-agent -n 50

# Verify MySQL connectivity
mysql -h$MYSQL_HOST -u$MYSQL_USER -p$MYSQL_PASS $MYSQL_DB
```

**2. No Logs Being Captured**
```bash
# Check if log file exists
ls -la /path/to/your/logfile

# Test error pattern
grep -E "ERROR|FATAL" /path/to/your/logfile | head -5

# Check agent is reading file
sudo lsof | grep tail | grep log-tail-mysql
```

**3. MySQL Connection Issues**
```bash
# Test from command line
mysql -h$MYSQL_HOST -P$MYSQL_PORT -u$MYSQL_USER -p$MYSQL_PASS $MYSQL_DB

# Check network connectivity  
telnet $MYSQL_HOST $MYSQL_PORT

# Verify user permissions
SHOW GRANTS FOR 'log_user'@'%';
```

**4. High CPU/Memory Usage**
```bash
# Check batch size (reduce if too high)
BATCH_SIZE="50"  # Instead of 300

# Check error pattern (make sure it's not too broad)
ERROR_PATTERN="ERROR|FATAL"  # Instead of catching everything

# Check for very long log lines
tail -n 100 /your/log/file | wc -L
```

### Performance Optimization

**For High Volume Servers:**
```bash
# Increase batch size, decrease flush interval
BATCH_SIZE="500"
FLUSH_INTERVAL="10" 

# Use more specific error patterns
ERROR_PATTERN="ERROR|FATAL|CRITICAL"  # Don't catch warnings
```

**For Network Issues:**
```bash
# Increase retry logic - modify script if needed
# Consider MySQL connection pooling
# Use local MySQL proxy/tunnel
```

**For Memory Constraints:**
```bash
# Reduce batch size
BATCH_SIZE="25"

# Ensure log rotation is working
# Check for extremely long error messages
```

## Log Rotation Handling

The agent automatically handles log rotation. For proper log management:

```bash
# Example logrotate config for your app logs
# /etc/logrotate.d/myapp
/var/log/application/*.log {
    daily
    missingok  
    rotate 7
    compress
    delaycompress
    notifempty
    copytruncate
}
```

## Security Considerations

1. **Database Security:**
   - Use dedicated MySQL user with minimal INSERT-only privileges
   - Enable MySQL SSL connections
   - Regularly rotate database passwords

2. **File Security:**
   - Protect configuration files containing passwords
   - Run agent with minimal required privileges
   - Secure log file access permissions

3. **Network Security:**
   - Configure security groups for MySQL port access
   - Consider VPN/private networking for database connections

## Best Practices

1. **Naming Convention:**
   - Use descriptive server names: `prod-web-01`, `staging-api-02`
   - Include environment and service type

2. **Monitoring:**
   - Set up alerts for agent failures
   - Monitor database table growth
   - Track error rates per server

3. **Maintenance:**
   - Regular database cleanup
   - Log rotation configuration  
   - Periodic connection testing

4. **Scaling:**
   - Adjust batch sizes based on actual log volumes
   - Consider multiple agents per server for different log files
   - Use database partitioning for very large datasets

---

This agent provides efficient, low-impact error log centralization for your existing MySQL infrastructure. The lightweight design ensures minimal resource usage while providing real-time error monitoring across your EC2 fleet.