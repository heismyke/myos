#!/usr/bin/bash
# Boots a full Plasma 6 X11 session with the ZumaOS theme inside the Debian
# dev image, at the Figma desktop size (1440x1024), and saves a screenshot.
#   dev/run-session.sh out.png [seconds-to-wait] [command-to-run-in-session]
# Like the OS image build, the throwaway container gets branding/ rendered,
# files/ and the packages/ applets and QML modules copied over /. The home
# directory is fresh, so the global theme's first-login layout runs each time.
set -euo pipefail

root=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
out=${1:?usage: run-session.sh out.png [wait] [command]}
wait=${2:-45}
cmd=${3:-}
mkdir -p "$root/dev/out"

docker run --rm --init --user root -v "$root":/src:ro -v "$root/dev/out":/out -w /src \
    -e WAIT="$wait" -e CMD="$cmd" -e OUT="/out/$(basename "$out")" zumaos-dev bash -c '
    set -e
    branding/render.sh / >/dev/null
    cp -r files/. /
    for pkg in packages/*/package; do
        id=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))[\"KPlugin\"][\"Id\"])" $pkg/metadata.json)
        cp -r $pkg /usr/share/plasma/plasmoids/$id
    done
    qml=/usr/lib/x86_64-linux-gnu/qt6/qml
    for mod in packages/*/qml; do cp -r $mod/. $qml/; done
    fc-cache -f >/dev/null

    runuser -u dev -- bash -c "
        export HOME=/tmp/home XDG_RUNTIME_DIR=/tmp/runtime
        mkdir -p \$HOME/.config \$XDG_RUNTIME_DIR && chmod 700 \$XDG_RUNTIME_DIR
        # No systemd user instance in a container: use the classic startup path.
        printf \"[General]\\nsystemdBoot=false\\n\" > \$HOME/.config/startkderc
        xvfb-run -a -s \"-screen 0 1440x1024x24\" dbus-run-session -- bash -c \"
            startplasma-x11 >/tmp/session.log 2>&1 &
            sleep \\\$WAIT
            if [ -n \\\"\\\$CMD\\\" ]; then bash -c \\\"\\\$CMD\\\" >>/tmp/session.log 2>&1 || true; sleep 4; fi
            import -window root \\\$OUT
        \" 2>/dev/null
    "
    grep -iE "error|warning|unavailable|not a type|failed|is not" /tmp/session.log \
        | grep -viE "kglobalaccel|rfkill|ScreenBrightness|session backend|xdg-desktop-portal|baloo|Activit|kded|polkit|bluez|NetworkManager|ModemManager|upower|powerdevil|pipewire|pulse|geoclue|kwallet|ksmserver|libinput|kscreen|drkonqi|ALSA|udisks|ICE-unix|systemd|X11 connection" \
        | sort | uniq -c | sort -rn | head -30
    '
