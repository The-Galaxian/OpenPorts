#!/bin/bash

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt

[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"

get_controls

GAMEDIR="/$directory/ports/yolkheroes/"
CONFDIR="$GAMEDIR/conf/"
# Ensure the conf directory exists
mkdir -p "$GAMEDIR/conf"

# Set the XDG environment variables for config & savefiles
export XDG_CONFIG_HOME="$CONFDIR"
export XDG_DATA_HOME="$CONFDIR"

# Keyboard Entry; edit name here
export TEXTINPUTPRESET="NAME"         # defines preset text to insert
export TEXTINPUTINTERACTIVE="Y"        # enables interactive text input mode
export TEXTINPUTNOAUTOCAPITALS="Y"     # disables automatic capitalisation of first letter of words in interactive text input mode
export TEXTINPUTADDEXTRASYMBOLS="Y"    # enables additional symbols for interactive text input

cd $GAMEDIR

runtime="frt_3.5.2"
if [ ! -f "$controlfolder/libs/${runtime}.squashfs" ]; then
  # Check for runtime if not downloaded via PM
  if [ ! -f "$controlfolder/harbourmaster" ]; then
    echo "This port requires the latest PortMaster to run, please go to https://portmaster.games/ for more info." > /dev/tty0
    sleep 5
    exit 1
  fi

  $ESUDO $controlfolder/harbourmaster --quiet --no-check runtime_check "${runtime}.squashfs"
fi

# Setup Godot
godot_dir="$HOME/godot"
godot_file="$controlfolder/libs/${runtime}.squashfs"
$ESUDO mkdir -p "$godot_dir"
$ESUDO umount "$godot_file" || true
$ESUDO mount "$godot_file" "$godot_dir"
PATH="$godot_dir:$PATH"

export FRT_NO_EXIT_SHORTCUTS=FRT_NO_EXIT_SHORTCUTS

$GPTOKEYB "$runtime" -c "./yolkheroes.gptk" &
pm_platform_helper "$runtime"
SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig" "$runtime" $GODOT_OPTS --main-pack "gamedata/yolkheroes.pck"

if [[ "$PM_CAN_MOUNT" != "N" ]]; then
  $ESUDO umount "$godot_dir"
fi

pm_finish
