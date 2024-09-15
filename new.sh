#!/bin/bash


LOG_FILE="systems.log"
KEYWORDS="ERROR|FAIL"
POSITION_FILE="last_position.txt"


if [ ! -f "$POSITION_FILE" ]; then
  echo 0 > "$POSITION_FILE"
fi

get_recent_logs() {
  local start_position=$1
  local current_position
  current_position=$(stat -c %s "$LOG_FILE") 

  
  dd if="$LOG_FILE" bs=1 skip="$start_position" 2>/dev/null | while read -r line; do
    
    log_timestamp=$(echo "$line" | awk '{print $1" "$2" "$3}')

    
    year=$(date +"%Y")

    
    log_time_seconds=$(date -d "$log_timestamp $year" +%s 2>/dev/null)

    
    if [ $? -ne 0 ]; then
      continue  
    fi

    
    time_diff=$((current_time - log_time_seconds))

    if [ "$time_diff" -le 600 ]; then
      echo "$line"
    fi
   done
}


check_for_errors() {
  local recent_logs="$1"
  if echo "$recent_logs" | grep -E "$KEYWORDS" >/dev/null; then
    echo "ALERT: Error detected in the logs!"
  fi
}


while true; do

  last_position=$(cat "$POSITION_FILE")

  current_time=$(date +%s)

  recent_logs=$(get_recent_logs "$last_position")

  check_for_errors "$recent_logs"

  echo "$(stat -c %s "$LOG_FILE")" > "$POSITION_FILE"

done
