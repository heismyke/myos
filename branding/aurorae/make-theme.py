#!/usr/bin/env python3
"""Generate the ZumaOS Aurorae window decoration (Windows 11-style caption buttons).

Aurorae draws the frame with Plasma's 9-slice FrameSvg: each element below is a
fixed-size tile (corners) or a stretched tile (edges, centre). QtSvg renders it,
so shadows are gradients rather than blur filters, which QtSvg ignores.

Usage: make-theme.py OUTDIR
"""
import pathlib
import sys

# Shadow padding around the window, corner radius, title bar height.
PL = PR = 22
PT, PB = 16, 28
R = 8
TITLE = 32

# Title bar colours are the colour scheme's Header background, so the title
# bar and the app's toolbar read as one surface, like Windows 11's Mica.
ACTIVE = dict(title="#242426", shadow=0.55)
INACTIVE = dict(title="#1E1E20", shadow=0.30)

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


def shadow(prefix, alpha):
    """Shadow shapes around a window at (PL, PT, WC, HC)."""
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
        f'<rect x="{x0}" y="0" width="{WC}" height="{y0}" fill="url(#{prefix}st)"/>',
        f'<rect x="{x0}" y="{y1}" width="{WC}" height="{PB}" fill="url(#{prefix}sb)"/>',
        f'<rect x="0" y="{y0}" width="{PL}" height="{HC}" fill="url(#{prefix}sl)"/>',
        f'<rect x="{x1}" y="{y0}" width="{PR}" height="{HC}" fill="url(#{prefix}sr)"/>',
        f'<rect x="{x0}" y="{y0}" width="{WC}" height="{HC}" fill-opacity="{alpha}"/>',
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
        shapes.append(f'<rect x="{qx}" y="{qy}" width="{rx}" height="{ry}" fill="url(#{prefix}c{name})"/>')
    return g, shapes


def window(color, rounded=True):
    x0, y0, x1, y1 = PL, PT, PL + WC, PT + HC
    if not rounded:
        return f'<rect x="{x0}" y="{y0}" width="{WC}" height="{HC}" fill="{color}"/>'
    return (
        f'<path fill="{color}" d="M{x0} {y0 + R} A{R} {R} 0 0 1 {x0 + R} {y0} H{x1 - R} '
        f'A{R} {R} 0 0 1 {x1} {y0 + R} V{y1} H{x0} Z"/>'
        # Hairline highlight along the top edge, so dark windows separate.
        f'<path fill="none" stroke="#FFFFFF" stroke-opacity=".08" stroke-width="1" '
        f'd="M{x0 + 0.5} {y0 + R} A{R - 0.5} {R - 0.5} 0 0 1 {x0 + R} {y0 + 0.5} H{x1 - R} '
        f'A{R - 0.5} {R - 0.5} 0 0 1 {x1 - 0.5} {y0 + R}"/>'
    )


def frame(prefix, style, offset_y, maximized=False):
    """One complete 9-slice frame, shifted down by offset_y so frames don't overlap."""
    pid = prefix.replace("-", "")
    defs, body = ([], []) if maximized else shadow(pid, style["shadow"])
    body.append(window(style["title"], rounded=not maximized))
    art = "".join(body)
    out = []
    for pos, (x, y, w, h) in TILES.items():
        cid = f"{pid}{pos}clip"
        defs.append(f'<clipPath id="{cid}"><rect x="{x}" y="{y}" width="{w}" height="{h}"/></clipPath>')
        out.append(
            f'<g id="{prefix}-{pos}" transform="translate(0 {offset_y})">'
            f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="#000" fill-opacity="0"/>'
            f'<g clip-path="url(#{cid})">{art}</g></g>'
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


# Caption buttons are full title-bar height and flush right, as in Windows 11.
BW, BH = 46, TITLE
GLYPH = "#E5E5EA"
GLYPH_INACTIVE = "#8E8E93"

BUTTONS = {
    # name: (glyph path, hover fill, pressed fill, glyph colour on hover)
    "minimize": ("M18 16.5 H28", "#FFFFFF14", "#FFFFFF0B", GLYPH),
    "maximize": ("M19.5 11.5 H26.5 A1.5 1.5 0 0 1 28 13 V20 A1.5 1.5 0 0 1 26.5 21.5 H19.5 "
                 "A1.5 1.5 0 0 1 18 20 V13 A1.5 1.5 0 0 1 19.5 11.5 Z", "#FFFFFF14", "#FFFFFF0B", GLYPH),
    "restore": ("M19.5 13.5 H24.5 A1.5 1.5 0 0 1 26 15 V20 A1.5 1.5 0 0 1 24.5 21.5 H19.5 "
                "A1.5 1.5 0 0 1 18 20 V15 A1.5 1.5 0 0 1 19.5 13.5 Z M20.5 11.5 H26.5 "
                "A1.5 1.5 0 0 1 28 13 V19", "#FFFFFF14", "#FFFFFF0B", GLYPH),
    "close": ("M18 11.5 L28 21.5 M28 11.5 L18 21.5", "#C42B1C", "#A8261A", "#FFFFFF"),
}


def fill(color):
    """#RRGGBBAA -> fill attributes QtSvg understands."""
    if len(color) == 9:
        return f'fill="{color[:7]}" fill-opacity="{int(color[7:], 16) / 255:.3f}"'
    return f'fill="{color}"'


def button(name, symbol, hover, pressed, hover_glyph):
    # The close button sits in the window's rounded top-right corner.
    corner = name == "close"

    def background(x, color):
        if corner:
            return (f'<path {fill(color)} d="M{x} 0 H{x + BW - R} A{R} {R} 0 0 1 {x + BW} {R} '
                    f'V{BH} H{x} Z"/>')
        return f'<rect x="{x}" y="0" width="{BW}" height="{BH}" {fill(color)}/>'

    def state(sid, x, bg, glyph):
        return (
            f'<g id="{sid}-center"><rect x="{x}" y="0" width="{BW}" height="{BH}" fill="#000" fill-opacity="0"/>'
            + (background(x, bg) if bg else "")
            + f'<path d="{symbol}" transform="translate({x} 0)" fill="none" stroke="{glyph}" '
            f'stroke-width="1" stroke-linecap="round" stroke-linejoin="round"/></g>'
        )
    step = BW + 2
    parts = [
        state("active", 0, None, GLYPH),
        state("hover", step, hover, hover_glyph),
        state("pressed", 2 * step, pressed, hover_glyph),
        state("inactive", 3 * step, None, GLYPH_INACTIVE),
        state("deactivated", 4 * step, None, "#5A5A5E"),
    ]
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{5 * step - 2}" height="{BH}">'
            f'{"".join(parts)}</svg>')


RC = f"""[General]
ActiveTextColor=229,229,234
InactiveTextColor=142,142,147
TitleAlignment=Left
TitleVerticalAlignment=Center
Animation=150
UseTextShadow=false
HaloActive=false
HaloInactive=false

[Layout]
BorderLeft=1
BorderRight=1
BorderBottom=1
TitleEdgeTop=0
TitleEdgeBottom=0
TitleEdgeLeft=10
TitleEdgeRight=0
TitleBorderLeft=8
TitleBorderRight=8
TitleHeight={TITLE}
ButtonWidth={BW}
ButtonHeight={BH}
ButtonSpacing=0
ButtonMarginTop=0
ExplicitButtonSpacer=10
PaddingTop={PT}
PaddingBottom={PB}
PaddingLeft={PL}
PaddingRight={PR}
TitleEdgeTopMaximized=0
TitleEdgeBottomMaximized=0
TitleEdgeLeftMaximized=10
TitleEdgeRightMaximized=0
TitleBorderLeftMaximized=8
TitleBorderRightMaximized=8
"""

METADATA_DESKTOP = """[Desktop Entry]
Name=ZumaOS
Comment=Windows 11-style window decoration for ZumaOS
X-KDE-PluginInfo-Name=ZumaOS
X-KDE-PluginInfo-Author=ZumaOS
X-KDE-PluginInfo-Version=1.0
X-KDE-PluginInfo-License=GPL-2.0-or-later
"""

METADATA_JSON = """{
    "KPlugin": {
        "Authors": [{ "Name": "ZumaOS" }],
        "Description": "Windows 11-style window decoration for ZumaOS",
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
    for name, (symbol, hover, pressed, glyph) in BUTTONS.items():
        (out / f"{name}.svg").write_text(button(name, symbol, hover, pressed, glyph))
    (out / "ZumaOSrc").write_text(RC)
    (out / "metadata.desktop").write_text(METADATA_DESKTOP)
    (out / "metadata.json").write_text(METADATA_JSON)


if __name__ == "__main__":
    main()
