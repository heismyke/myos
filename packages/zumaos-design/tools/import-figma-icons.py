#!/usr/bin/python3
"""Normalise SVG icons exported by the Figma MCP server for Qt.

Figma wraps each Material Symbols glyph in a mask that covers the whole
viewBox with `mask-type:alpha`. QtSvg ignores mask-type and applies it as a
luminance mask, which draws the glyph at ~85% opacity. A mask that covers the
whole canvas is a no-op, so it is removed; the glyph paths are left untouched.

Usage: import-figma-icons.py ICON.svg...   (rewrites files in place)
"""
import re
import sys

MASK = re.compile(
    r'<mask id="(?P<id>[^"]+)"[^>]*x="0" y="0" width="(?P<w>\d+)" height="(?P<h>\d+)">\s*'
    r'<rect[^>]*width="(?P=w)" height="(?P=h)"[^>]*/>\s*</mask>\s*')

for path in sys.argv[1:]:
    svg = open(path).read()
    m = MASK.search(svg)
    if not m:
        continue
    svg = svg[:m.start()] + svg[m.end():]
    svg = svg.replace(f' mask="url(#{m["id"]})"', "")
    open(path, "w").write(svg)
    print(f"{path}: removed full-canvas mask {m['id']}")
