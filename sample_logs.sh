#!/bin/bash

# Sample Log Generator for Testing Log Tail Agent
# Creates various log files with ERROR entries for testing

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Create sample application log (Java Spring Boot style)
create_spring_boot_log() {
    local log_file="$1"
    print_status "Creating Spring Boot style log: $log_file"
    
    cat > "$log_file" <<EOF
2025-01-15 08:30:12.123 INFO  [main] com.example.Application - Starting Application
2025-01-15 08:30:13.456 INFO  [main] com.example.config.DatabaseConfig - Connecting to database
2025-01-15 08:30:14.789 WARN  [main] com.example.config.DatabaseConfig - Connection pool near capacity
2025-01-15 08:30:15.012 INFO  [http-nio-8080-exec-1] com.example.controller.UserController - Processing user request
2025-01-15 08:30:16.345 ERROR [http-nio-8080-exec-1] com.example.service.UserService - Failed to authenticate user: InvalidCredentialsException
2025-01-15 08:30:17.678 INFO  [http-nio-8080-exec-2] com.example.controller.OrderController - Creating new order
2025-01-15 08:30:18.901 ERROR [http-nio-8080-exec-2] com.example.service.PaymentService - Payment gateway timeout: SocketTimeoutException
2025-01-15 08:30:19.234 FATAL [task-executor-1] com.example.service.EmailService - SMTP server unreachable, email service down
2025-01-15 08:30:20.567 INFO  [http-nio-8080-exec-3] com.example.controller.ProductController - Fetching product catalog
2025-01-15 08:30:21.890 WARN  [http-nio-8080-exec-3] com.example.service.CacheService - Cache miss for product catalog
2025-01-15 08:30:22.123 ERROR [scheduler-1] com.example.job.DataSyncJob - Database sync failed: SQLException - Connection timed out
2025-01-15 08:30:23.456 CRITICAL [health-check] com.example.health.DatabaseHealthCheck - Database health check failed - system critical
2025-01-15 08:30:24.789 INFO  [http-nio-8080-exec-4] com.example.controller.ApiController - API request processed successfully
2025-01-15 08:30:25.012 ERROR [async-task-1] com.example.service.NotificationService - Failed to send push notification: ConnectionRefusedException
EOF
}

# Create sample Node.js/Express log
create_nodejs_log() {
    local log_file="$1"
    print_status "Creating Node.js style log: $log_file"
    
    cat > "$log_file" <<EOF
2025-01-15T08:30:12.123Z [INFO] Server started on port 3000
2025-01-15T08:30:13.456Z [INFO] Connected to MongoDB at mongodb://localhost:27017
2025-01-15T08:30:14.789Z [DEBUG] Route /api/users - GET request received
2025-01-15T08:30:15.012Z [WARN] Rate limit exceeded for IP 192.168.1.100
2025-01-15T08:30:16.345Z [ERROR] Authentication failed for user john.doe@example.com - Invalid token
2025-01-15T08:30:17.678Z [INFO] POST /api/orders - Order created successfully
2025-01-15T08:30:18.901Z [ERROR] Database connection lost - MongoNetworkError: Connection timed out
2025-01-15T08:30:19.234Z [FATAL] Critical security breach detected - Multiple failed login attempts
2025-01-15T08:30:20.567Z [INFO] Cache warmed up successfully
2025-01-15T08:30:21.890Z [DEBUG] Processing background job: email-sender
2025-01-15T08:30:22.123Z [ERROR] Failed to process payment - Stripe API error: card_declined
2025-01-15T08:30:23.456Z [WARN] Memory usage at 85% - Consider scaling up
2025-01-15T08:30:24.789Z [ERROR] Redis connection failed - ECONNREFUSED 127.0.0.1:6379
2025-01-15T08:30:25.012Z [CRITICAL] Service mesh communication failure - Circuit breaker activated
EOF
}

# Create sample Python Django/Flask log
create_python_log() {
    local log_file="$1"
    print_status "Creating Python style log: $log_file"
    
    cat > "$log_file" <<EOF
[2025-01-15 08:30:12,123] INFO in app: Application startup complete
[2025-01-15 08:30:13,456] INFO in database: PostgreSQL connection established
[2025-01-15 08:30:14,789] DEBUG in views: Processing GET request for /dashboard
[2025-01-15 08:30:15,012] WARNING in auth: User session expired for user_id: 12345
[2025-01-15 08:30:16,345] ERROR in models: Database integrity error - Duplicate key violation
[2025-01-15 08:30:17,678] INFO in tasks: Background task 'data_export' queued
[2025-01-15 08:30:18,901] ERROR in external_api: HTTP 503 Service Unavailable from payment processor
[2025-01-15 08:30:19,234] CRITICAL in security: SQL injection attempt detected from IP 10.0.0.1
[2025-01-15 08:30:20,567] INFO in cache: Redis cache hit rate: 78%
[2025-01-15 08:30:21,890] DEBUG in middleware: Request processing time: 245ms
[2025-01-15 08:30:22,123] ERROR in celery: Task 'send_email' failed - SMTPException: Connection refused
[2025-01-15 08:30:23,456] FATAL in core: Out of memory error - Application restart required
[2025-01-15 08:30:24,789] WARNING in monitoring: High CPU usage detected (>90%)
[2025-01-15 08:30:25,012] ERROR in upload: File upload failed - Disk space insufficient
EOF
}

# Create sample Nginx access/error log
create_nginx_log() {
    local log_file="$1"
    print_status "Creating Nginx style error log: $log_file"
    
    cat > "$log_file" <<EOF
2025/01/15 08:30:12 [info] 12345#0: Using the "epoll" event method
2025/01/15 08:30:13 [info] 12346#0: Worker process started
2025/01/15 08:30:14 [warn] 12346#0: *1024 upstream server temporarily disabled while reading response header from upstream
2025/01/15 08:30:15 [error] 12346#0: *1025 connect() failed (111: Connection refused) while connecting to upstream
2025/01/15 08:30:16 [info] 12346#0: *1026 client 192.168.1.100 closed connection while reading client request
2025/01/15 08:30:17 [error] 12346#0: *1027 FastCGI sent in stderr: "PHP message: Fatal error: Uncaught Exception"
2025/01/15 08:30:18 [crit] 12346#0: *1028 SSL_do_handshake() failed (SSL: error:14094418:SSL routines:ssl3_read_bytes:tlsv1 alert unknown ca)
2025/01/15 08:30:19 [error] 12346#0: *1029 upstream timed out (110: Connection timed out) while reading response header
2025/01/15 08:30:20 [warn] 12346#0: *1030 client sent HTTP/1.1 request without hostname
2025/01/15 08:30:21 [error] 12346#0: *1031 open() "/var/www/html/favicon.ico" failed (2: No such file or directory)
2025/01/15 08:30:22 [emerg] 12346#0: bind() to 0.0.0.0:80 failed (98: Address already in use)
2025/01/15 08:30:23 [alert] 12345#0: worker process 12346 exited on signal 11 (core dumped)
2025/01/15 08:30:24 [error] 12347#0: *1032 recv() failed (104: Connection reset by peer) while reading response header
2025/01/15 08:30:25 [crit] 12347#0: *1033 SSL certificate verify failed while SSL handshaking
EOF
}

# Create sample Apache error log
create_apache_log() {
    local log_file="$1"
    print_status "Creating Apache style error log: $log_file"
    
    cat > "$log_file" <<EOF
[Mon Jan 15 08:30:12.123456 2025] [mpm_prefork:notice] [pid 12345] AH00163: Apache/2.4.41 configured
[Mon Jan 15 08:30:13.456789 2025] [ssl:info] [pid 12345] AH01914: Configuring server for SSL protocol
[Mon Jan 15 08:30:14.789012 2025] [rewrite:error] [pid 12346] [client 192.168.1.100:54321] AH00670: Options ExecCGI is off in this directory
[Mon Jan 15 08:30:15.012345 2025] [php7:error] [pid 12346] [client 192.168.1.101:54322] PHP Fatal error: Uncaught Error: Call to undefined function mysql_connect()
[Mon Jan 15 08:30:16.345678 2025] [core:error] [pid 12346] [client 192.168.1.102:54323] AH00124: Request exceeded the limit of 10 internal redirects
[Mon Jan 15 08:30:17.678901 2025] [ssl:warn] [pid 12345] AH01909: RSA certificate configured for www.example.com:443 does NOT include an ID
[Mon Jan 15 08:30:18.901234 2025] [proxy_http:error] [pid 12347] (111)Connection refused: AH00957: HTTP: attempt to connect to backend failed
[Mon Jan 15 08:30:19.234567 2025] [core:crit] [pid 12347] [client 192.168.1.103:54324] AH00529: /var/www/.htaccess pcfg_openfile: unable to check htaccess file, ensure it is readable
[Mon Jan 15 08:30:20.567890 2025] [auth_digest:error] [pid 12348] [client 192.168.1.104:54325] AH01793: invalid qop
[Mon Jan 15 08:30:21.890123 2025] [reqtimeout:info] [pid 12348] [client 192.168.1.105:54326] AH07951: Request header read timeout
[Mon Jan 15 08:30:22.123456 2025] [proxy:error] [pid 12349] AH00898: Error during SSL Handshake with remote server
[Mon Jan 15 08:30:23.456789 2025] [core:emerg] [pid 12345] AH00020: Configuration Failed, exiting
[Mon Jan 15 08:30:24.789012 2025] [mpm_prefork:error] [pid 12350] AH00161: server reached MaxRequestWorkers setting
[Mon Jan 15 08:30:25.012345 2025] [ssl:error] [pid 12350] AH02032: Hostname provided via SNI not found in certificate
EOF
}

# Create sample MySQL error log
create_mysql_log() {
    local log_file="$1"
    print_status "Creating MySQL style error log: $log_file"
    
    cat > "$log_file" <<EOF
2025-01-15T08:30:12.123456Z 0 [System] [MY-010116] [Server] /usr/sbin/mysqld (mysqld 8.0.35) starting as process 12345
2025-01-15T08:30:13.456789Z 0 [System] [MY-010229] [Server] Starting crash recovery...
2025-01-15T08:30:14.789012Z 0 [System] [MY-010232] [Server] Crash recovery finished.
2025-01-15T08:30:15.012345Z 0 [Warning] [MY-010068] [Server] CA certificate ca.pem is self signed.
2025-01-15T08:30:16.345678Z 8 [ERROR] [MY-000000] [Server] Access denied for user 'root'@'localhost' (using password: YES)
2025-01-15T08:30:17.678901Z 0 [System] [MY-011323] [Server] X Plugin ready for connections. Bind-address: '::' port: 33060
2025-01-15T08:30:18.901234Z 9 [ERROR] [MY-001049] [Server] Unknown database 'nonexistent_db'
2025-01-15T08:30:19.234567Z 10 [ERROR] [MY-001146] [Server] Table 'test.missing_table' doesn't exist
2025-01-15T08:30:20.567890Z 0 [ERROR] [MY-010119] [Server] Aborting
2025-01-15T08:30:21.890123Z 11 [Warning] [MY-001681] [Server] 'user' entry 'test@localhost' ignored in --skip-name-resolve mode.
2025-01-15T08:30:22.123456Z 12 [ERROR] [MY-001045] [Server] Access denied for user 'backup'@'192.168.1.100' (using password: NO)
2025-01-15T08:30:23.456789Z 0 [ERROR] [MY-000067] [Server] unknown variable 'invalid_setting=ON'
2025-01-15T08:30:24.789012Z 13 [ERROR] [MY-001184] [Server] Aborted connection 13 to db: 'production' user: 'app_user' host: '192.168.1.101' (Got timeout reading communication packets)
2025-01-15T08:30:25.012345Z 0 [ERROR] [MY-013183] [Server] Failed to initialize DD Storage Engine
EOF
}

# Create sample Docker container log
create_docker_log() {
    local log_file="$1"
    print_status "Creating Docker style log: $log_file"
    
    cat > "$log_file" <<EOF
{"log":"2025-01-15T08:30:12.123Z [INFO] Application starting...\n","stream":"stdout","time":"2025-01-15T08:30:12.123456789Z"}
{"log":"2025-01-15T08:30:13.456Z [INFO] Connected to database\n","stream":"stdout","time":"2025-01-15T08:30:13.456789012Z"}
{"log":"2025-01-15T08:30:14.789Z [WARN] Configuration file not found, using defaults\n","stream":"stderr","time":"2025-01-15T08:30:14.789012345Z"}
{"log":"2025-01-15T08:30:15.012Z [ERROR] Failed to bind to port 8080: address already in use\n","stream":"stderr","time":"2025-01-15T08:30:15.012345678Z"}
{"log":"2025-01-15T08:30:16.345Z [INFO] Retrying on port 8081\n","stream":"stdout","time":"2025-01-15T08:30:16.345678901Z"}
{"log":"2025-01-15T08:30:17.678Z [ERROR] Database connection pool exhausted\n","stream":"stderr","time":"2025-01-15T08:30:17.678901234Z"}
{"log":"2025-01-15T08:30:18.901Z [FATAL] Out of memory: cannot allocate buffer\n","stream":"stderr","time":"2025-01-15T08:30:18.901234567Z"}
{"log":"2025-01-15T08:30:19.234Z [CRITICAL] Service mesh unavailable - circuit breaker open\n","stream":"stderr","time":"2025-01-15T08:30:19.234567890Z"}
{"log":"2025-01-15T08:30:20.567Z [INFO] Health check endpoint configured\n","stream":"stdout","time":"2025-01-15T08:30:20.567890123Z"}
{"log":"2025-01-15T08:30:21.890Z [ERROR] Kubernetes readiness probe failed\n","stream":"stderr","time":"2025-01-15T08:30:21.890123456Z"}
{"log":"2025-01-15T08:30:22.123Z [WARN] CPU usage high: 95%\n","stream":"stdout","time":"2025-01-15T08:30:22.123456789Z"}
{"log":"2025-01-15T08:30:23.456Z [ERROR] Failed to write to persistent volume: disk full\n","stream":"stderr","time":"2025-01-15T08:30:23.456789012Z"}
{"log":"2025-01-15T08:30:24.789Z [INFO] Graceful shutdown initiated\n","stream":"stdout","time":"2025-01-15T08:30:24.789012345Z"}
{"log":"2025-01-15T08:30:25.012Z [ERROR] Shutdown timeout exceeded, forcing exit\n","stream":"stderr","time":"2025-01-15T08:30:25.012345678Z"}
EOF
}

# Function to continuously append to log (for testing real-time tailing)
simulate_realtime_logs() {
    local log_file="$1"
    print_status "Simulating real-time logs to: $log_file"
    print_warning "Press Ctrl+C to stop simulation"
    
    error_types=("ERROR" "FATAL" "CRITICAL")
    services=("UserService" "PaymentService" "EmailService" "DatabaseService" "CacheService")
    errors=("Connection timeout" "Authentication failed" "Out of memory" "Disk full" "Network unreachable" "Invalid configuration" "Service unavailable")
    
    while true; do
        timestamp=$(date '+%Y-%m-%d %H:%M:%S.%3N')
        error_type=${error_types[$RANDOM % ${#error_types[@]}]}
        service=${services[$RANDOM % ${#services[@]}]}
        error=${errors[$RANDOM % ${#errors[@]}]}
        
        echo "[$timestamp] $error_type [$service] $error - Exception occurred during request processing" >> "$log_file"
        sleep $((RANDOM % 10 + 1))  # Random delay 1-10 seconds
    done
}

# Main function
main() {
    local output_dir="logs"
    
    case "${1:-}" in
        "spring"|"java")
            mkdir -p "$output_dir"
            create_spring_boot_log "$output_dir/spring-boot.log"
            ;;
        "node"|"nodejs")
            mkdir -p "$output_dir"
            create_nodejs_log "$output_dir/nodejs.log"
            ;;
        "python"|"django"|"flask")
            mkdir -p "$output_dir"
            create_python_log "$output_dir/python-app.log"
            ;;
        "nginx")
            mkdir -p "$output_dir"
            create_nginx_log "$output_dir/nginx-error.log"
            ;;
        "apache")
            mkdir -p "$output_dir"
            create_apache_log "$output_dir/apache-error.log"
            ;;
        "mysql")
            mkdir -p "$output_dir"
            create_mysql_log "$output_dir/mysql-error.log"
            ;;
        "docker")
            mkdir -p "$output_dir"
            create_docker_log "$output_dir/docker-container.log"
            ;;
        "realtime")
            local target_file="${2:-./test-realtime.log}"
            simulate_realtime_logs "$target_file"
            ;;
        "all"|"")
            mkdir -p "$output_dir"
            create_spring_boot_log "$output_dir/spring-boot.log"
            create_nodejs_log "$output_dir/nodejs.log"
            create_python_log "$output_dir/python-app.log"
            create_nginx_log "$output_dir/nginx-error.log"
            create_apache_log "$output_dir/apache-error.log"
            create_mysql_log "$output_dir/mysql-error.log"
            create_docker_log "$output_dir/docker-container.log"
            ;;
        *)
            cat <<EOF
Sample Log Generator for Testing

Usage: $0 [type]

Types:
  spring       - Java Spring Boot application logs
  node         - Node.js/Express application logs
  python       - Python Django/Flask logs
  nginx        - Nginx error logs
  apache       - Apache error logs
  mysql        - MySQL error logs
  docker       - Docker container logs (JSON format)
  realtime     - Continuous log simulation (Ctrl+C to stop)
  all          - Generate all sample log types (default)

Examples:
  $0              # Generate all sample logs in ./sample-logs/
  $0 spring       # Generate only Spring Boot logs
  $0 realtime     # Start real-time log simulation
  $0 realtime /tmp/test.log  # Real-time logs to specific file

Output: All logs saved to ./sample-logs/ directory
EOF
            ;;
    esac
    
    if [[ "${1:-}" != "realtime" && "${1:-}" != "" && "${1:-}" != "all" ]]; then
        echo
        print_status "Sample log created! Test with:"
        echo "  tail -f $output_dir/*.log"
        echo "  /usr/local/opt/log-tail-agent/log-tail-mysql.sh"
    elif [[ "${1:-}" == "" || "${1:-}" == "all" ]]; then
        echo
        print_status "All sample logs created in: $output_dir/"
        echo
        echo "Test your agent with any of these:"
        ls -la "$output_dir/"
        echo
        echo "Update your log-tail.conf with:"
        echo "  LOG_FILE=\"$(pwd)/$output_dir/spring-boot.log\""
    fi
}

main "$@"