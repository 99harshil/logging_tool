#!/bin/sh

# Directory containing raw log files
LOG_DIR="/path/to/logs"

# Directory to store processed logs
PROCESSED_DIR="/path/to/processed_logs"

# Ensure the processed logs directory exists
mkdir -p "$PROCESSED_DIR"

# Loop through all log files in the log directory
for log_file in "$LOG_DIR"/*.log; do
    echo "Processing file: $log_file"
    
    # Check if the log file already has line numbers (e.g., if it starts with a number)
    if [[ $(head -n 1 "$log_file") =~ ^[0-9]+: ]]; then
        echo "Log file $log_file already has line numbers. Skipping..."
    else
        echo "Adding line numbers to $log_file..."
        
        # Process the log file by adding line numbers using `nl`
        processed_file="$PROCESSED_DIR/$(basename "$log_file")"
        nl -ba "$log_file" > "$processed_file"
        
        echo "Processed file saved to $processed_file"
    fi
done
