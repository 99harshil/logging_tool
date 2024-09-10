# Logging Tool with Elasticsearch, Kibana, and Filebeat

## Description
This project demonstrates how to use command line tool for log parsing based on filter, time series range.

### Prerequisites
- Python

### Step 1: Running Instruction
python manual_parser --help
python manual_pasrser.py ./logs "304" --files=nginx_access.log --start-time='2015-05-17 08:05:20' --end-time='2015-05-17 08:05:30' 
