#!/usr/bin/bash
# Loads the Quick Settings applet in plasmoidviewer (Plasma 6.3, Debian 13)
# inside the dev image, prints QML warnings, and saves a screenshot.
#   dev/run-applet.sh out.png
# No NetworkManager, BlueZ, PipeWire or PowerDevil run in the container, so
# this checks that the applet loads and degrades cleanly; device behaviour
# needs the VM.
set -euo pipefail

root=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
out=${1:?usage: run-applet.sh out.png}

docker run --rm --init -v "$root":/src:Z -w /src zumaos-dev bash -c '
    set -e
    export QML_IMPORT_PATH=/src/packages/zumaos-design/qml
    export FONTCONFIG_FILE=/src/dev/preview/fontconfig/fonts.conf
    xvfb-run -a -s "-screen 0 1024x900x24" dbus-run-session -- bash -c "
        plasmoidviewer -a /src/packages/zumaos-quicksettings/package -f planar -s 560x780 2>&1 &
        sleep 8
        import -window root /src/'"$out"'
        kill %1
    "' 2>&1 | grep -v -e '^$' -e 'Kirigami platform' | head -40
