#!/usr/bin/bash
# Renders the ZumaOS branding sources into the files the image needs. Runs in
# the "assets" build stage; output is laid out as a root filesystem under $1.
set -euo pipefail

src=$(dirname "$(readlink -f "$0")")
out=$1
logos=$out/usr/share/zumaos-logos
wallpapers=$out/usr/share/wallpapers
plymouth=$out/usr/share/plymouth/themes/zumaos
mkdir -p "$logos" "$plymouth"

cd "$src"

# Logo: the website logo as a rounded-square app icon. The SVG embeds the
# rendered PNG so it stays a single self-contained file.
rsvg-convert -w 256 -h 256 -o "$logos/zumaos-logo.png" logo-tile.svg
rsvg-convert -w 64 -h 64 -o "$logos/zumaos-logo-small.png" logo-tile.svg
{
    printf '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 256 256" width="256" height="256">'
    printf '<image width="256" height="256" xlink:href="data:image/png;base64,%s"/></svg>\n' \
        "$(base64 -w0 "$logos/zumaos-logo.png")"
} > "$logos/zumaos-logo.svg"
cp glyph.svg "$logos/zumaos-symbolic.svg"
rsvg-convert -w 64 -h 64 -o "$logos/zumaos-symbolic.png" glyph.svg

# Settings app icon. A name Papirus doesn't have, so it comes from hicolor.
icons=$out/usr/share/icons/hicolor/scalable/apps
mkdir -p "$icons"
cp icons/zumaos-settings.svg icons/zumaos-launcher.svg "$icons/"

# Wordmark: white "Zuma" + violet "OS", for dark backgrounds.
cp zumaos-wordmark.png "$logos/zumaos-wordmark.png"
python3 - "$logos" "$plymouth" <<'EOF'
import sys
from PIL import Image
logos, plymouth = sys.argv[1:]
mark = Image.open(f"{logos}/zumaos-wordmark.png")
for height, path in ((48, f"{logos}/zumaos-wordmark-small.png"), (64, f"{plymouth}/watermark.png")):
    mark.resize((round(mark.width * height / mark.height), height), Image.LANCZOS).save(path)
EOF

# Wallpapers: "ZumaOS" is the Figma design's purple waves (1440x1024, the
# only size the design has). "ZumaOS Rock" switches between the day and night
# Zuma Rock photos with the colour scheme; "ZumaOS Moonrise" is the second
# night photo.
package() {
    local id=$1 name=$2 light=$3 dark=${4:-}
    local dir=$wallpapers/$id/contents
    local size
    mkdir -p "$dir/images"
    size=$(python3 -c 'import sys; from PIL import Image; print("%dx%d" % Image.open(sys.argv[1]).size)' "wallpapers/$light")
    cp "wallpapers/$light" "$dir/images/$size.${light##*.}"
    if [ -n "$dark" ]; then
        mkdir -p "$dir/images_dark"
        cp "wallpapers/$dark" "$dir/images_dark/$size.${dark##*.}"
    fi
    python3 - "wallpapers/${dark:-$light}" "$dir/screenshot.jpg" <<'EOF'
import sys
from PIL import Image
Image.open(sys.argv[1]).resize((640, 357), Image.LANCZOS).save(sys.argv[2], quality=85)
EOF
    cat > "$wallpapers/$id/metadata.json" <<EOF
{
    "KPlugin": {
        "Authors": [{ "Name": "ZumaOS" }],
        "Id": "$id",
        "License": "CC-BY-SA-4.0",
        "Name": "$name"
    }
}
EOF
}
package ZumaOS "ZumaOS" waves.png
package ZumaOS-Rock "ZumaOS Rock" day.jpg night.jpg
package ZumaOS-Moonrise "ZumaOS Moonrise" moonrise.jpg

# Window decoration, from the Figma window frame.
python3 aurorae/make-theme.py "$out/usr/share/aurorae/themes/ZumaOS"

# Plasma theme: the Figma shelf, its pill task buttons and popups.
python3 desktoptheme/make-theme.py "$out/usr/share/plasma/desktoptheme/ZumaOS"

# Boot splash parts. two-step plays throbber-* while booting and animation-*
# at the end.
for name in entry bullet lock; do
    rsvg-convert -o "$plymouth/$name.png" "plymouth/$name.svg"
done
for i in $(seq 1 30); do
    frame=$(printf %04d "$i")
    sed "s/@ROT@/$((i * 12))/" plymouth/throbber.svg \
        | rsvg-convert -o "$plymouth/throbber-$frame.png"
    cp "$plymouth/throbber-$frame.png" "$plymouth/animation-$frame.png"
done
