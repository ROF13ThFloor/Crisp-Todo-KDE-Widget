#!/usr/bin/env bash
# Install (or update) the Crisp Todo plasmoid for the current user.
set -e
cd "$(dirname "$0")"

if kpackagetool5 -t Plasma/Applet -l | grep -qx "com.github.rof13thfloor.crisptodo"; then
    kpackagetool5 -t Plasma/Applet -u crisp-todo
    echo "Updated. Restart Plasma to reload a widget that is already placed:"
    echo "    plasmashell --replace & disown"
else
    kpackagetool5 -t Plasma/Applet -i crisp-todo
    echo "Installed. Right-click your panel/desktop -> Add Widgets -> search 'Crisp Todo'."
fi
echo "Quick preview in a window:  plasmawindowed com.github.rof13thfloor.crisptodo"
