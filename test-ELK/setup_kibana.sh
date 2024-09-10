#!/bin/sh

# Timeout for waiting (in seconds)
timeout=120
start_time=$(date +%s)

# Wait for Kibana to be ready
until $(curl --output /dev/null --silent --head --fail http://kibana:5601); do
  echo "Waiting for Kibana..."
  sleep 5

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

# Create a visualization for message count
VIS_MESSAGE_COUNT=$(curl -X POST "http://kibana:5601/api/saved_objects/visualization" \
-H "kbn-xsrf: true" \
-H "Content-Type: application/json" \
-d '{
  "attributes": {
    "title": "Message Count",
    "visState": "{\"title\":\"Message Count\",\"type\":\"metric\",\"params\":{\"fontSize\":\"20\"},\"aggs\":[{\"id\":\"1\",\"enabled\":true,\"type\":\"count\",\"schema\":\"metric\",\"params\":{}}]}",
    "uiStateJSON": "{}",
    "description": "",
    "version": 1,
    "kibanaSavedObjectMeta": {
      "searchSourceJSON": "{\"index\":\"filebeat-*\",\"query\":{\"query\":\"\",\"language\":\"kuery\"},\"filter\":[]}"
    }
  }
}')

# Extract the visualization ID manually from the response
VIS_MESSAGE_COUNT_ID=$(echo $VIS_MESSAGE_COUNT | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')

# Create a visualization for file path
VIS_FILE_PATH=$(curl -X POST "http://kibana:5601/api/saved_objects/visualization" \
-H "kbn-xsrf: true" \
-H "Content-Type: application/json" \
-d '{
  "attributes": {
    "title": "File Path",
    "visState": "{\"title\":\"File Path\",\"type\":\"table\",\"params\":{\"perPage\":10},\"aggs\":[{\"id\":\"1\",\"enabled\":true,\"type\":\"terms\",\"schema\":\"bucket\",\"params\":{\"field\":\"log_file.keyword\",\"size\":10,\"order\":\"desc\"}}]}",
    "uiStateJSON": "{}",
    "description": "",
    "version": 1,
    "kibanaSavedObjectMeta": {
      "searchSourceJSON": "{\"index\":\"filebeat-*\",\"query\":{\"query\":\"\",\"language\":\"kuery\"},\"filter\":[]}"
    }
  }
}')
VIS_FILE_PATH_ID=$(echo $VIS_FILE_PATH | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')

# Create a visualization for line number
VIS_LINE_NUMBER=$(curl -X POST "http://kibana:5601/api/saved_objects/visualization" \
-H "kbn-xsrf: true" \
-H "Content-Type: application/json" \
-d '{
  "attributes": {
    "title": "Line Number",
    "visState": "{\"title\":\"Line Number\",\"type\":\"table\",\"params\":{\"perPage\":10},\"aggs\":[{\"id\":\"1\",\"enabled\":true,\"type\":\"terms\",\"schema\":\"bucket\",\"params\":{\"field\":\"log.offset\",\"size\":10,\"order\":\"desc\"}}]}",
    "uiStateJSON": "{}",
    "description": "",
    "version": 1,
    "kibanaSavedObjectMeta": {
      "searchSourceJSON": "{\"index\":\"filebeat-*\",\"query\":{\"query\":\"\",\"language\":\"kuery\"},\"filter\":[]}"
    }
  }
}')
VIS_LINE_NUMBER_ID=$(echo $VIS_LINE_NUMBER | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')

# Create a dashboard and add the visualizations to it
curl -X POST "http://kibana:5601/api/saved_objects/dashboard" \
-H "kbn-xsrf: true" \
-H "Content-Type: application/json" \
-d "{
    \"attributes\": {
      \"title\": \"Log Message Dashboard\",
      \"panelsJSON\": \"[
        {\\\"panelIndex\\\":\\\"1\\\",\\\"gridData\\\":{\\\"x\\\":0,\\\"y\\\":0,\\\"w\\\":24,\\\"h\\\":15,\\\"i\\\":\\\"1\\\"},\\\"version\\\":\\\"7.10.0\\\",\\\"type\\\":\\\"visualization\\\",\\\"id\\\":\\\"$VIS_MESSAGE_COUNT_ID\\\"},
        {\\\"panelIndex\\\":\\\"2\\\",\\\"gridData\\\":{\\\"x\\\":0,\\\"y\\\":15,\\\"w\\\":24,\\\"h\\\":15,\\\"i\\\":\\\"2\\\"},\\\"version\\\":\\\"7.10.0\\\",\\\"type\\\":\\\"visualization\\\",\\\"id\\\":\\\"$VIS_FILE_PATH_ID\\\"},
        {\\\"panelIndex\\\":\\\"3\\\",\\\"gridData\\\":{\\\"x\\\":0,\\\"y\\\":30,\\\"w\\\":24,\\\"h\\\":15,\\\"i\\\":\\\"3\\\"},\\\"version\\\":\\\"7.10.0\\\",\\\"type\\\":\\\"visualization\\\",\\\"id\\\":\\\"$VIS_LINE_NUMBER_ID\\\"}
      ]\"
    }
}"

echo "Kibana dashboard with visualizations created!"
