# Point this shell at the desktop session that is actually on the screen.
# Source it:  source /usr/local/lib/muse/desktop-env.sh
runtime=/run/user/@DESKTOP_UID@
if [ -d "$runtime" ]; then
  export XDG_RUNTIME_DIR="$runtime"
  export DBUS_SESSION_BUS_ADDRESS="unix:path=$runtime/bus"
  for sock in "$runtime"/wayland-*; do
    if [ -S "$sock" ]; then
      WAYLAND_DISPLAY=${sock##*/}
      export WAYLAND_DISPLAY
      break
    fi
  done
fi
if [ -S /tmp/.X11-unix/X1 ]; then
  export DISPLAY=:1
fi
export XDG_CURRENT_DESKTOP=COSMIC
export XDG_SESSION_TYPE=wayland
