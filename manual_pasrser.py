import os
import argparse

def find_log_files(directory):
    """
    Finds all .log files in the provided directory.
    """
    log_files = []
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(".log"):
                log_files.append(os.path.join(root, file))
    return log_files

def search_in_logs(log_files, keyword):
    """
    Searches for the keyword in each log file and prints the matching lines.
    """
    for log_file in log_files:
        try:
            with open(log_file, 'r') as file:
                for line in file:
                    if keyword in line:
                        print(f"[{log_file}] {line.strip()}")
        except Exception as e:
            print(f"Error reading {log_file}: {e}")

def main():
    parser = argparse.ArgumentParser(description="Log file monitoring and filtering script.")
    parser.add_argument("dir", help="Directory path to search for .log files.", type=str)
    parser.add_argument("filter", help="Keyword to filter log lines.", type=str)
    
    args = parser.parse_args()
    
    # Find all .log files in the directory
    log_files = find_log_files(args.dir)
    
    if not log_files:
        print("No .log files found in the provided directory.")
        return
    
    print(f"Found {len(log_files)} log file(s). Searching for '{args.filter}'...")
    
    # Search for the filter keyword in the log files
    search_in_logs(log_files, args.filter)

if __name__ == "__main__":
    main()
