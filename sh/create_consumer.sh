rm -f ~/consumer.sh
echo '#!/bin/sh

# Variables
VHOST="%2F" # URL-encoded "/"
QUEUE_NAME="my_queue"
USERNAME="RabbitAdm"
PASSWORD='\''!qaz2wsx3edc'\'' # Password in single quotes to escape special characters
HOST="rmq.pam4.com"

# Retrieve messages from the queue
RESPONSE=$(curl -s -u "$USERNAME:$PASSWORD" -H "content-type:application/json" \
 -XPOST -d'\''{"count":100,"ackmode":"ack_requeue_false","encoding":"auto"}'\'' \
 http://$HOST:15672/api/queues/$VHOST/$QUEUE_NAME/get)

# Check if there are messages
if [ "$RESPONSE" = "[]" ]; then
    echo "Queue is empty"
    exit 0
fi

# If jq is installed, process the messages
if command -v jq > /dev/null 2>&1; then
    echo "$RESPONSE" | jq -c '\''.[]'\'' | while read -r ITEM; do
        PAYLOAD=$(echo "$ITEM" | jq -r '\''.payload'\'')
        SERVER_NAME=$(echo "$PAYLOAD" | jq -r '\''.server_name'\'')
        CPU_LOAD=$(echo "$PAYLOAD" | jq -r '\''.cpu_load'\'')
        TIMESTAMP=$(echo "$PAYLOAD" | jq -r '\''.timestamp'\'')
        echo "Server: $SERVER_NAME, CPU Load: $CPU_LOAD, Timestamp: $TIMESTAMP"
    done
else
    # If jq is not installed, output the raw response
    echo "Received messages:"
    echo "$RESPONSE"
fi
' > ~/consumer.sh

chmod +x ~/consumer.sh
