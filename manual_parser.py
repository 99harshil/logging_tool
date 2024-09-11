import os
import re
import json
import argparse
from datetime import datetime

RESET = "\033[0m"        # Reset color
PINK = "\033[95m"        # Magenta (close to pink)

# Timestamp formats for different log types
TIMESTAMP_FORMATS = {
    'default': "%Y-%m-%d %H:%M:%S",       # Python log format
    'nginx': "%d/%b/%Y:%H:%M:%S %z",      # Nginx log format
    'grafana': "%Y-%m-%dT%H:%M:%SZ",      # Grafana log format (ISO)
    'linux': "%b %d %H:%M:%S",            # Linux system log format (e.g., Sep  6 10:15:45)
    # Add more formats as needed
}

def find_log_files(directory, specific_files=None):
    """
    Finds .log files in the provided directory.
    If specific_files are provided, only include those.
    """
    log_files = []
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(".log") or 'log' in file:
                if specific_files and file not in specific_files:
                    continue
                log_files.append(os.path.join(root, file))
    return log_files

def parse_timestamp_from_line(line, log_type):
    """
    Extracts and parses the timestamp from a log line based on the log type.
    """
    try:
        if log_type == 'nginx':
            match = re.search(r'\[(.*?)\]', line)
            if match:
                timestamp_str = match.group(1).split()[0]
                return datetime.strptime(timestamp_str, "%d/%b/%Y:%H:%M:%S")
        elif log_type == 'grafana':
            log_data = json.loads(line)
            timestamp_str = log_data.get('t', None)
            if timestamp_str:
                return datetime.strptime(timestamp_str, TIMESTAMP_FORMATS['grafana'])
        elif log_type == 'linux':
            timestamp_str = " ".join(line.split()[:3])
            return datetime.strptime(timestamp_str, TIMESTAMP_FORMATS['linux'])
        else:
            timestamp_str = line.split()[0] + " " + line.split()[1]
            return datetime.strptime(timestamp_str, TIMESTAMP_FORMATS['default'])
    except (IndexError, ValueError, json.JSONDecodeError):
        return None

def identify_log_type(log_file):
    """
    Identifies the log type based on the file name or its content.
    """
    if 'nginx' in log_file.lower():
        return 'nginx'
    elif 'grafana' in log_file.lower():
        return 'grafana'
    elif 'syslog' in log_file.lower() or 'auth.log' in log_file.lower():
        return 'linux'  # Linux system log
    else:
        return 'default'  # Default to Python log format

def search_in_logs(log_files, keyword, start_time=None, end_time=None):
    """
    Searches for the keyword in each log file and prints the matching lines within the time range.
    """
    for log_file in log_files:
        log_type = identify_log_type(log_file)
        print(f"{PINK}Parsing '{log_file}' as {log_type} logs.{RESET}")
        try:
            with open(log_file, 'r') as file:
                for line in file:
                    timestamp = parse_timestamp_from_line(line, log_type)
                    if timestamp:
                        if start_time and timestamp < start_time:
                            continue
                        if end_time and timestamp > end_time:
                            continue
                    if keyword in line:
                        print(f"[{log_file}] {line.strip()}")
        except Exception as e:
            print(f"Error reading {log_file}: {e}")

def main():
    parser = argparse.ArgumentParser(
        description="Universal log file monitoring script. Supports Nginx, Python, Grafana, Linux logs.",
        formatter_class=argparse.RawTextHelpFormatter
    )
    
    parser.add_argument("dir", help="Directory path to search for log files.", type=str)
    parser.add_argument("filter", help="Keyword to filter log lines.", type=str)
    parser.add_argument("--files", help="Comma-separated list of specific file names to search within.", type=str)
    parser.add_argument("--start-time", help="Start time for filtering logs (format: 'YYYY-MM-DD HH:MM:SS').", type=str)
    parser.add_argument("--end-time", help="End time for filtering logs (format: 'YYYY-MM-DD HH:MM:SS').", type=str)
    
    args = parser.parse_args()

    # Parse the provided start and end times
    start_time = None
    end_time = None
    if args.start_time:
        try:
            start_time = datetime.strptime(args.start_time, TIMESTAMP_FORMATS['default'])
        except ValueError:
            print("Invalid start time format. Please use 'YYYY-MM-DD HH:MM:SS'.")
            return
    if args.end_time:
        try:
            end_time = datetime.strptime(args.end_time, TIMESTAMP_FORMATS['default'])
        except ValueError:
            print("Invalid end time format. Please use 'YYYY-MM-DD HH:MM:SS'.")
            return
    
    # Parse specific file names if provided
    specific_files = args.files.split(",") if args.files else None
    
    # Find log files (either specific ones or all in the directory)
    log_files = find_log_files(args.dir, specific_files)
    
    if not log_files:
        print("No log files found in the provided directory.")
        return
    
    print(f"{PINK}Found {len(log_files)} log file(s). Searching for '{args.filter}'...{RESET}")
    
    # Search for the filter keyword in the log files within the time range
    search_in_logs(log_files, args.filter, start_time, end_time)

if __name__ == "__main__":
    main()
