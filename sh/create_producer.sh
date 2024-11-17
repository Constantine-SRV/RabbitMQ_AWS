cat << 'EOF' > ~/producer.sh
#!/bin/sh

# Define server and password variables
RMQ_HOST="rmq.pam4.com"
PASSWORD='!qaz2wsx3edc' # Password in single quotes to escape special characters

# Get server name, CPU load, and timestamp
SERVER_NAME=$(hostname)
CPU_LOAD=$(uptime | awk -F"load average:" '{ print $2 }' | cut -d"," -f1 | xargs)
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Construct JSON message with timestamp
MESSAGE="{\"server_name\": \"$SERVER_NAME\", \"cpu_load\": \"$CPU_LOAD\", \"timestamp\": \"$TIMESTAMP\"}"

# Publish message to my_queue using amqp-publish
amqp-publish --url="amqp://RabbitWriter:${PASSWORD}@${RMQ_HOST}:5672/%2F" -r my_queue -b "$MESSAGE"

# Output information about the sent message
echo "Sent message: $MESSAGE"
EOF

chmod +x ~/producer.sh
