#!/bin/sh

# Timeout for waiting (in seconds)
timeout=120
start_time=$(date +%s)

# Wait for Kibana to be ready
until $(curl --output /dev/null --silent --head --fail http://kibana:5601); do
  echo "Waiting for Kibana..."
  sleep 5

  # Check if timeout has passed
  current_time=$(date +%s)
  elapsed_time=$((current_time - start_time))

  if [ $elapsed_time -ge $timeout ]; then
    echo "Timeout reached while waiting for Kibana."
    exit 1
  fi
done

# Create the index pattern in Kibana using the API
curl -X POST "http://kibana:5601/api/saved_objects/index-pattern" \
-H "kbn-xsrf: true" \
-H "Content-Type: application/json" \
-d '{
  "attributes": {
    "title": "filebeat-*",
    "timeFieldName": "@timestamp"
  }
}'

echo "Index pattern 'filebeat-*' created in Kibana!"
