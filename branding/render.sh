#!/usr/bin/bash
# Renders the ZumaOS SVG sources into the PNGs the image needs. Runs in the
# "assets" build stage; output is laid out as a root filesystem under $1.
set -euo pipefail

src=$(dirname "$(readlink -f "$0")")
out=$1
logos=$out/usr/share/zumaos-logos
wallpaper=$out/usr/share/wallpapers/ZumaOS/contents
plymouth=$out/usr/share/plymouth/themes/zumaos
mkdir -p "$logos" "$wallpaper/images" "$plymouth"

cd "$src"
cp logo.svg "$logos/zumaos-logo.svg"
rsvg-convert -w 256 -h 256 -o "$logos/zumaos-logo.png" logo.svg
rsvg-convert -w 64 -h 64 -o "$logos/zumaos-logo-small.png" logo.svg
rsvg-convert -h 128 -o "$logos/zumaos-wordmark.png" wordmark.svg
rsvg-convert -h 48 -o "$logos/zumaos-wordmark-small.png" wordmark.svg

rsvg-convert -w 3840 -h 2160 -o "$wallpaper/images/3840x2160.png" wallpaper.svg
rsvg-convert -w 640 -h 360 -o "$wallpaper/screenshot.png" wallpaper.svg

rsvg-convert -w 112 -h 112 -o "$plymouth/watermark.png" logo.svg
for name in entry bullet lock; do
    rsvg-convert -o "$plymouth/$name.png" "plymouth/$name.svg"
done
# two-step plays throbber-* while booting and animation-* at the end.
for i in $(seq 1 30); do
    frame=$(printf %04d "$i")
    sed "s/@ROT@/$((i * 12))/" plymouth/throbber.svg \
        | rsvg-convert -o "$plymouth/throbber-$frame.png"
    cp "$plymouth/throbber-$frame.png" "$plymouth/animation-$frame.png"
done
