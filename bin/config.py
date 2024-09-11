"""Set the configuration for the type of log files"""
from typing import TypedDict

class LogConfiguration(TypedDict):
  log_type: str
  timestamp_format: str
  

class LogConfig:
  
  def __init__(self, log_type: str) -> None:
    self.log_type = log_type
  
  
  def get_log_configuration(self) -> LogConfiguration:
    
    log_configuration: LogConfiguration
    
    if (self.log_type == "nginx"):
      log_configuration = {
        "log_type": "nginx",
        "timestamp_format": "%d/%b/%Y:%H:%M:%S %z"
      }
    else:
      log_configuration = {
        "log_type": "default",
        "timestamp_format": "%Y-%m-%d %H:%M:%S"
      }
      
    return log_configuration