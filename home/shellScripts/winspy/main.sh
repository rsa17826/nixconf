#!/bin/bash

# Function to fetch and format window data
get_window_info() {
  window_data=$(hyprctl activewindow -j)

  # Check if a window is actually focused
  if [[ $(echo "$window_data" | jq -r '.address') == "0x" ]]; then
    echo "No active window detected."
    return
  fi

  echo "--- Hyprland Window Spy ---"
  echo "Title:    $(echo "$window_data" | jq -r '.title')"
  echo "Class:    $(echo "$window_data" | jq -r '.class')"
  echo "Address:  $(echo "$window_data" | jq -r '.address')"
  echo "Workspace ID: $(echo "$window_data" | jq -r '.workspace.id')"
  echo "Floating: $(echo "$window_data" | jq -r '.floating')"
  echo "Monitor:  $(echo "$window_data" | jq -r '.monitor')"
  echo "PID:      $(echo "$window_data" | jq -r '.pid')"
  echo "---------------------------"
}

# Use 'watch' to refresh the info every 0.1 seconds
export -f get_window_info
watch -n 0.1 -t bash -c get_window_info
