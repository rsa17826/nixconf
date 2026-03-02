#!/bin/bash
# Wait until the user stops moving for 2 seconds to "prime" it
swayidle -w \
  timeout 2 'hyprlock; pkill -u $USER swayidle' \
  resume 'hyprlock; pkill -u $USER swayidle'
