#!/bin/bash
# 1. We wait for 2 seconds of stillness to "arm" the trap.
# 2. 'resume' only fires once the user moves AFTER that timeout.
# 3. We kill swayidle immediately so it doesn't loop.

swayidle -w \
  timeout 2 'echo "Armed..." ' \
  resume 'hyprlock; pkill -u $USER swayidle'
