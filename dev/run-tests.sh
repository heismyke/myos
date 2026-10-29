#!/usr/bin/bash
# Runs the QML component tests in the Debian dev image.
set -euo pipefail

root=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)

docker run --rm --init -v "$root":/src:Z -w /src zumaos-dev \
    xvfb-run -a -s '-screen 0 1280x1024x24' \
    env QML_IMPORT_PATH=/src/packages/zumaos-design/qml \
        /usr/lib/qt6/bin/qmltestrunner -input packages/zumaos-quicksettings/tests
