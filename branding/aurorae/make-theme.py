#!/usr/bin/env python3
"""Generate the ZumaOS Aurorae window decoration from the Figma design.

The design (Settings window, Figma node 1:19043, drawn at 3840px; values here
are scaled by 0.375 to the 1440px desktop frames) has a white 37px title bar
with 8px top corners and a 3px #2D2D2D outline, close / maximise / minimise
glyphs flush left, a centred bold title, and no buttons on the right.

Aurorae draws the frame with Plasma's 9-slice FrameSvg: each element below is a
fixed-size tile (corners) or a stretched tile (edges, centre). QtSvg renders it,
so shadows are gradients rather than blur filters, which QtSvg ignores. KSvg
sizes a tile from its element's geometric bounds and ignores clip paths, so
every tile holds only the shapes inside it, cut to its rectangle here.

Usage: make-theme.py OUTDIR
"""
import pathlib
import re
import sys

# Shadow padding around the window, corner radius, title bar height, outline.
PL = PR = 22
PT, PB = 16, 28
R = 8
TITLE = 37
STROKE = 3
OUTLINE = "#2D2D2D"

# Figma has only the active window. Inactive keeps the white bar and greys
# the title and glyphs (see RC and GLYPH_INACTIVE). Figma draws no shadow;
# one is kept so windows separate from each other.
ACTIVE = dict(title="#FFFFFF", shadow=0.55)
INACTIVE = dict(title="#FFFFFF", shadow=0.30)

# Drawing area for one frame: the window sits at (PL, PT) with this size.
WC, HC = 4 * R, 4 * R
W, H = PL + WC + PR, PT + HC + PB

TILES = {
    "topleft": (0, 0, PL + R, PT + R),
    "top": (PL + R, 0, WC - 2 * R, PT + R),
    "topright": (PL + WC - R, 0, R + PR, PT + R),
    "left": (0, PT + R, PL + R, HC - 2 * R),
    "center": (PL + R, PT + R, WC - 2 * R, HC - 2 * R),
    "right": (PL + WC - R, PT + R, R + PR, HC - 2 * R),
    "bottomleft": (0, PT + HC - R, PL + R, R + PB),
    "bottom": (PL + R, PT + HC - R, WC - 2 * R, R + PB),
    "bottomright": (PL + WC - R, PT + HC - R, R + PR, R + PB),
}


def stops(alpha):
    # Ease the falloff so the shadow fades softly, like a blur would.
    return (
        f'<stop offset="0" stop-opacity="{alpha}"/>'
        f'<stop offset=".35" stop-opacity="{alpha * 0.45:.3f}"/>'
        f'<stop offset="1" stop-opacity="0"/>'
    )


def rect(x, y, w, h, attrs):
    return ("rect", x, y, w, h, attrs)


def quarter(cx, cy, r, sx, sy, attrs, stroke=False):
    """Quarter disc (or, with stroke, arc) of radius r around (cx, cy),
    towards (sx, sy); its bounding square is (cx + min(0, sx * r), ...)."""
    return ("quarter", cx, cy, r, sx, sy, attrs, stroke)


def shadow(prefix, alpha):
    """Shadow gradients and shapes around a window at (PL, PT, WC, HC)."""
    x0, y0, x1, y1 = PL, PT, PL + WC, PT + HC
    s = stops(alpha)
    g = [
        f'<linearGradient id="{prefix}st" x1="0" y1="0" x2="0" y2="{y0}" gradientUnits="userSpaceOnUse">'
        f'<stop offset="0" stop-opacity="0"/><stop offset="1" stop-opacity="{alpha * 0.6:.3f}"/></linearGradient>',
        f'<linearGradient id="{prefix}sb" x1="0" y1="{y1}" x2="0" y2="{H}" gradientUnits="userSpaceOnUse">{s}</linearGradient>',
        f'<linearGradient id="{prefix}sl" x1="{x0}" y1="0" x2="0" y2="0" gradientUnits="userSpaceOnUse">{s}</linearGradient>',
        f'<linearGradient id="{prefix}sr" x1="{x1}" y1="0" x2="{W}" y2="0" gradientUnits="userSpaceOnUse">{s}</linearGradient>',
    ]
    shapes = [
        rect(x0, 0, WC, y0, f'fill="url(#{prefix}st)"'),
        rect(x0, y1, WC, PB, f'fill="url(#{prefix}sb)"'),
        rect(0, y0, PL, HC, f'fill="url(#{prefix}sl)"'),
        rect(x1, y0, PR, HC, f'fill="url(#{prefix}sr)"'),
    ]
    # Corners: elliptical radial gradients centred on each window corner.
    for name, cx, cy, rx, ry, top in (
        ("tl", x0, y0, PL, PT, True), ("tr", x1, y0, PR, PT, True),
        ("bl", x0, y1, PL, PB, False), ("br", x1, y1, PR, PB, False),
    ):
        a = alpha * 0.6 if top else alpha
        g.append(
            f'<radialGradient id="{prefix}c{name}" cx="{cx}" cy="{cy}" r="{rx}" gradientUnits="userSpaceOnUse" '
            f'gradientTransform="translate({cx} {cy}) scale(1 {ry / rx:.4f}) translate({-cx} {-cy})">{stops(a)}</radialGradient>'
        )
        qx = cx - rx if cx == x0 else cx
        qy = cy - ry if cy == y0 else cy
        shapes.append(rect(qx, qy, rx, ry, f'fill="url(#{prefix}c{name})"'))
    # Behind the rounded corners, the top shadow's strength; under the window
    # itself, the full shadow in the window's shape.
    top = f'fill="#000" fill-opacity="{alpha * 0.6:.3f}"'
    shapes += [rect(x0, y0, R, R, top), rect(x1 - R, y0, R, R, top)]
    shapes += window_fill(f'fill="#000" fill-opacity="{alpha}"', rounded=True)
    return g, shapes


def window_fill(attrs, rounded):
    """The window's area: rounded top corners as quarter discs, the rest as
    rects that stop at the tile boundaries."""
    x0, y0, x1 = PL, PT, PL + WC
    if not rounded:
        return [rect(x0, y0, WC, HC, attrs)]
    return [
        quarter(x0 + R, y0 + R, R, -1, -1, attrs),
        quarter(x1 - R, y0 + R, R, 1, -1, attrs),
        rect(x0 + R, y0, WC - 2 * R, R, attrs),
        rect(x0, y0 + R, WC, HC - R, attrs),
    ]


def window(color, rounded=True):
    """The frame: white fill with the outline inside its edge. Borders are as
    wide as the outline, so below the title bar only the outline shows."""
    x0, y0, x1, y1 = PL, PT, PL + WC, PT + HC
    line = f'fill="{OUTLINE}"'
    shapes = window_fill(f'fill="{color}"', rounded)
    r = R if rounded else 0
    if rounded:
        arc = f'fill="none" stroke="{OUTLINE}" stroke-width="{STROKE}"'
        shapes += [quarter(x0 + R, y0 + R, R, -1, -1, arc, stroke=True),
                   quarter(x1 - R, y0 + R, R, 1, -1, arc, stroke=True)]
    shapes += [
        rect(x0 + r, y0, WC - 2 * r, STROKE, line),
        rect(x0, y0 + r, STROKE, HC - r, line),
        rect(x1 - STROKE, y0 + r, STROKE, HC - r, line),
        rect(x0, y1 - STROKE, WC, STROKE, line),
    ]
    return shapes


def cut(shape, tx, ty, tw, th):
    """SVG for the part of `shape` inside the tile, or "" if none."""
    if shape[0] == "rect":
        _, x, y, w, h, attrs = shape
        ax, ay = max(x, tx), max(y, ty)
        bx, by = min(x + w, tx + tw), min(y + h, ty + th)
        if bx <= ax or by <= ay:
            return ""
        return f'<rect x="{ax}" y="{ay}" width="{bx - ax}" height="{by - ay}" {attrs}/>'
    _, cx, cy, r, sx, sy, attrs, stroke = shape
    qx, qy = cx + min(0, sx * r), cy + min(0, sy * r)
    if qx >= tx + tw or qx + r <= tx or qy >= ty + th or qy + r <= ty:
        return ""
    # Tile boundaries sit on corner radii, so a quarter is never split.
    assert tx <= qx and qx + r <= tx + tw and ty <= qy and qy + r <= ty + th
    sweep = 1 if sx * sy > 0 else 0
    if stroke:
        ri = r - STROKE / 2
        return (f'<path d="M{cx + sx * ri},{cy} A{ri},{ri} 0 0 {sweep} {cx},{cy + sy * ri}" {attrs}/>')
    return (f'<path d="M{cx},{cy} H{cx + sx * r} A{r},{r} 0 0 {sweep} {cx},{cy + sy * r} Z" {attrs}/>')


def frame(prefix, style, offset_y, maximized=False):
    """One complete 9-slice frame, shifted down by offset_y so frames don't overlap."""
    pid = prefix.replace("-", "")
    defs, shapes = ([], []) if maximized else shadow(pid, style["shadow"])
    shapes += window(style["title"], rounded=not maximized)
    out = []
    for pos, (x, y, w, h) in TILES.items():
        art = "".join(cut(sh, x, y, w, h) for sh in shapes)
        # The transparent rect pins the tile's bounds to its full cell.
        out.append(
            f'<g id="{prefix}-{pos}" transform="translate(0 {offset_y})">'
            f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="#000" fill-opacity="0"/>{art}</g>'
        )
    return defs, out


def decoration():
    defs, groups = [], []
    for i, (prefix, style, maxi) in enumerate((
        ("decoration", ACTIVE, False),
        ("decoration-inactive", INACTIVE, False),
        ("decoration-maximized", ACTIVE, True),
        ("decoration-maximized-inactive", INACTIVE, True),
    )):
        d, g = frame(prefix, style, i * (H + 10), maxi)
        defs += d
        groups += g
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{4 * (H + 10)}">'
        f'<defs>{"".join(defs)}</defs>{"".join(groups)}</svg>'
    )


# Caption buttons are square, full title-bar height, flush left. Glyphs are
# the design's Material Symbols paths (glyphs/*.svg, 98.4615 units square).
BW = BH = TITLE
GLYPH = OUTLINE
GLYPH_INACTIVE = "#7B7B7B"
GLYPHS = pathlib.Path(__file__).with_name("glyphs")
# Figma has no hover/pressed states: a #2D2D2D wash at the Material
# state-layer opacities, as in the QML design system.
HOVER, PRESSED = 0.08, 0.12

# Restore has no glyph in the design; it reuses maximise.
BUTTONS = {"minimize": "minimize", "maximize": "maximize", "restore": "maximize", "close": "close"}


def glyph(name):
    return re.search(r' d="([^"]+)"', (GLYPHS / f"{name}.svg").read_text())[1]


def button(name, glyph_name):
    d = glyph(glyph_name)
    scale = BW / 98.4615

    def state(sid, x, wash, color):
        bg = (f'<circle cx="{x + BW / 2}" cy="{BH / 2}" r="{BW / 2 - 4}" fill="{OUTLINE}" '
              f'fill-opacity="{wash}"/>' if wash else "")
        return (
            f'<g id="{sid}-center"><rect x="{x}" y="0" width="{BW}" height="{BH}" fill="#000" fill-opacity="0"/>'
            f'{bg}<path d="{d}" fill="{color}" fill-rule="evenodd" '
            f'transform="translate({x} 0) scale({scale:.5f})"/></g>'
        )
    step = BW + 2
    parts = [
        state("active", 0, 0, GLYPH),
        state("hover", step, HOVER, GLYPH),
        state("pressed", 2 * step, PRESSED, GLYPH),
        state("inactive", 3 * step, 0, GLYPH_INACTIVE),
        state("deactivated", 4 * step, 0, "#C4C4C4"),
    ]
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{5 * step - 2}" height="{BH}">'
            f'{"".join(parts)}</svg>')


RC = f"""[General]
ActiveTextColor=45,45,45
InactiveTextColor=123,123,123
TitleAlignment=Center
TitleVerticalAlignment=Center
Animation=150
UseTextShadow=false
HaloActive=false
HaloInactive=false

[Layout]
BorderLeft={STROKE}
BorderRight={STROKE}
BorderBottom={STROKE}
TitleEdgeTop=0
TitleEdgeBottom=0
TitleEdgeLeft=0
TitleEdgeRight=0
TitleBorderLeft=8
TitleBorderRight=8
TitleHeight={TITLE}
ButtonWidth={BW}
ButtonHeight={BH}
ButtonSpacing=0
ButtonMarginTop=0
ExplicitButtonSpacer=0
PaddingTop={PT}
PaddingBottom={PB}
PaddingLeft={PL}
PaddingRight={PR}
TitleEdgeTopMaximized=0
TitleEdgeBottomMaximized=0
TitleEdgeLeftMaximized=0
TitleEdgeRightMaximized=0
TitleBorderLeftMaximized=8
TitleBorderRightMaximized=8
"""

METADATA_DESKTOP = """[Desktop Entry]
Name=ZumaOS
Comment=ZumaOS window decoration
X-KDE-PluginInfo-Name=ZumaOS
X-KDE-PluginInfo-Author=ZumaOS
X-KDE-PluginInfo-Version=1.0
X-KDE-PluginInfo-License=GPL-2.0-or-later
"""

METADATA_JSON = """{
    "KPlugin": {
        "Authors": [{ "Name": "ZumaOS" }],
        "Description": "ZumaOS window decoration",
        "Id": "ZumaOS",
        "License": "GPL-2.0-or-later",
        "Name": "ZumaOS",
        "Version": "1.0"
    }
}
"""


def main():
    out = pathlib.Path(sys.argv[1])
    out.mkdir(parents=True, exist_ok=True)
    (out / "decoration.svg").write_text(decoration())
    for name, glyph_name in BUTTONS.items():
        (out / f"{name}.svg").write_text(button(name, glyph_name))
    (out / "ZumaOSrc").write_text(RC)
    (out / "metadata.desktop").write_text(METADATA_DESKTOP)
    (out / "metadata.json").write_text(METADATA_JSON)


if __name__ == "__main__":
    main()
