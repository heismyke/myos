#!/usr/bin/bash
# Renders the Quick Settings preview inside the Debian dev image.
#   dev/run-preview.sh out.png [--tiles=network,bluetooth,...]
# The PNG lands relative to the repository root.
set -euo pipefail

root=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
out=${1:?usage: run-preview.sh out.png [qml args]}
shift

docker run --rm --init -v "$root":/src:Z -w /src zumaos-dev \
    xvfb-run -a -s '-screen 0 1280x1024x24' \
    env QML_IMPORT_PATH=/src/packages/zumaos-design/qml \
        FONTCONFIG_FILE=/src/dev/preview/fontconfig/fonts.conf \
        /usr/lib/qt6/bin/qml dev/preview/preview.qml -- "--screenshot=/src/$out" "$@"
