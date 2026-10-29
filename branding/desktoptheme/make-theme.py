#!/usr/bin/env python3
"""Generate the ZumaOS Plasma theme (panel, task buttons, popups) from the
Figma shelf (node 1:16858).

Plasma draws these with KSvg's 9-slice FrameSvg: for each prefix the SVG holds
<prefix>-topleft, -top, ... -bottomright tiles, plus optional
<prefix>-hint-{top,bottom,left,right}-margin rects that set the content
margins. Anything not generated here comes from the default (Breeze) theme,
which follows the ZumaOS colour scheme.

Usage: make-theme.py OUTDIR
"""
import json
import pathlib
import sys

SURFACE = "#2D2D2D"
CONTROL = "#9A9A9A"
WHITE = "#FFFFFF"
ATTENTION = "#FFD60A"  # not in Figma; the colour scheme's neutral colour
# Material state layer: white at 8% over the control colour (see Tokens.qml).
CONTROL_HOVER = "#A2A2A2"

SHELF_HEIGHT = 56
SHELF_RADIUS = 28  # top corners only; the shelf sits on the bottom edge
SHELF_PADDING = 8
TASK_SIZE = 40     # task buttons are 40px circles with a 24px icon
POPUP_RADIUS = 24  # not in Figma, which has no menus or popups
POPUP_PADDING = 12


def rect(id_, x, y, w, h, fill="none"):
    return f'<rect id="{id_}" x="{x}" y="{y}" width="{w}" height="{h}" fill="{fill}"/>'


def frame(prefix, y0, w, h, r, fill, margins, ring=None, square_bottom=False, inset=0):
    """One 9-slice frame of size w x h at (0, y0) with corner radius r.

    KSvg sizes each tile from its element's geometric bounds (clip paths are
    ignored), so every tile is drawn as its own shape: quarter discs for the
    corners, rects for the edges and centre. `ring` is an optional
    (colour, width) inner stroke; `square_bottom` keeps the bottom corners
    square; `inset` leaves that much transparent space on every side.
    """
    p = f"{prefix}-" if prefix else ""
    rb = 0 if square_bottom else r
    cb = rb or 1  # bottom corner tiles are 1px tall when square
    ring_colour, rw = ring or (None, 0)

    def box(x, y, tw, th, colour=fill):
        return f'<rect x="{x}" y="{y0 + y}" width="{tw}" height="{th}" fill="{colour}"/>'

    def corner(cx, cy, rad, sx, sy):
        """Quarter disc of radius rad around (cx, cy), opening towards (sx, sy)."""
        if rad == 0:
            return ""
        x1, y1 = cx + sx * rad, cy + sy * rad
        sweep = 1 if sx * sy > 0 else 0
        d = f"M{cx},{y0 + cy} H{x1} A{rad},{rad} 0 0 {sweep} {cx},{y0 + y1} Z"
        shape = f'<path d="{d}" fill="{fill}"/>'
        if ring:
            ri = rad - rw / 2
            ax, ay = cx + sx * ri, cy + sy * ri
            shape += (f'<path d="M{ax},{y0 + cy} A{ri},{ri} 0 0 {sweep} {cx},{y0 + ay}" '
                      f'fill="none" stroke="{ring_colour}" stroke-width="{rw}"/>')
        return shape

    def ring_edge(x, y, tw, th):
        return box(x, y, tw, th, ring_colour) if ring else ""

    # Shape edges: x from a to b, y from t to u. Tile boundaries sit a radius
    # in from them (c0, c1 across; m0, m1 down).
    a, b = inset, w - inset
    t, u = inset, h - inset
    c0, c1 = a + r, b - r
    m0, m1 = t + r, u - cb
    side, top_h, bot_h = r + inset, r + inset, cb + inset
    tiles = {
        "topleft": (0, 0, side, top_h, corner(c0, m0, r, -1, -1)),
        "top": (c0, 0, c1 - c0, top_h, box(c0, t, c1 - c0, r) + ring_edge(c0, t, c1 - c0, rw)),
        "topright": (c1, 0, side, top_h, corner(c1, m0, r, 1, -1)),
        "left": (0, m0, side, m1 - m0, box(a, m0, r, m1 - m0) + ring_edge(a, m0, rw, m1 - m0)),
        "center": (c0, m0, c1 - c0, m1 - m0, box(c0, m0, c1 - c0, m1 - m0)),
        "right": (c1, m0, side, m1 - m0, box(c1, m0, r, m1 - m0) + ring_edge(b - rw, m0, rw, m1 - m0)),
        "bottomleft": (0, m1, side, bot_h, corner(c0, u - rb, rb, -1, 1) if rb else box(a, m1, r, cb)),
        "bottom": (c0, m1, c1 - c0, bot_h, box(c0, m1, c1 - c0, cb) + ring_edge(c0, u - rw, c1 - c0, rw)),
        "bottomright": (c1, m1, side, bot_h, corner(c1, u - rb, rb, 1, 1) if rb else box(c1, m1, r, cb)),
    }
    out = []
    for name, (x, y, tw, th, art) in tiles.items():
        # The transparent rect pins the tile's bounds to its full cell.
        out.append(f'<g id="{p}{name}"><rect x="{x}" y="{y0 + y}" width="{tw}" height="{th}" '
                   f'fill="#000" fill-opacity="0"/>{art}</g>')
    # KSvg ignores a zero-sized hint and measures the tiles instead, so a
    # zero margin is drawn as a hair-thin one.
    top, bottom, left, right = (m or 0.01 for m in margins)
    out += [
        rect(f"{p}hint-top-margin", w + 4, y0, 1, top),
        rect(f"{p}hint-bottom-margin", w + 6, y0, 1, bottom),
        rect(f"{p}hint-left-margin", w + 8, y0, left, 1),
        rect(f"{p}hint-right-margin", w + 8, y0 + 2, right, 1),
    ]
    return "", out


def document(frames):
    defs, body, y = [], [], 0
    for kwargs in frames:
        h = kwargs.pop("h")
        d, b = frame(y0=y, h=h, **kwargs)
        defs.append(d)
        body += b
        y += h + 4
    width = max(f["w"] for f in frames) + 64
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{y}">'
            f'<defs>{"".join(defs)}</defs>\n' + "\n".join(body) + "\n</svg>\n")


def panel():
    # 4 * radius wide so every tile has room; the shelf's content height is
    # set by the panel thickness in the layout script.
    common = dict(w=4 * SHELF_RADIUS, h=2 * SHELF_RADIUS + 8, r=SHELF_RADIUS, fill=SURFACE,
                  margins=(SHELF_PADDING,) * 4, square_bottom=True)
    frames = [dict(prefix=p, **common) for p in ("", "south")]
    # Plasma's floating gap comes from the "floating" prefix's margins. Zero
    # margins keep the panel on the screen edges while still drawing all four
    # corners (a non-floating full-width panel drops its side borders, and
    # with them the rounded top corners).
    frames.append(dict(prefix="floating", w=4, h=4, r=1, fill="none", margins=(0, 0, 0, 0)))
    return document(frames)


def tasks():
    # The task manager ignores the panel padding and makes each button the
    # full shelf height (56px) square, plus its left and right margins. So
    # the margins are zero and the circle is inset 8px all round: a 40px
    # circle with a 24px icon. Buttons end up 16px apart, not Figma's 8.
    inset = (SHELF_HEIGHT - TASK_SIZE) // 2
    r = TASK_SIZE // 2
    pad = inset + (TASK_SIZE - 24) // 2
    # Drawn 8px larger than the button so the edge tiles aren't empty.
    size = SHELF_HEIGHT + 8
    common = dict(w=size, h=size, r=r, inset=inset, margins=(pad, pad, 0, 0))
    # "" is used for pinned launchers; "normal" for running apps.
    states = {
        "": dict(fill=CONTROL),
        "normal": dict(fill=CONTROL),
        "minimized": dict(fill=CONTROL),
        "focus": dict(fill=CONTROL, ring=(WHITE, 2)),
        "attention": dict(fill=CONTROL, ring=(ATTENTION, 2)),
        "hover": dict(fill=CONTROL_HOVER),
        "launcher-hover": dict(fill=CONTROL_HOVER),
        "focus-hover": dict(fill=CONTROL_HOVER, ring=(WHITE, 2)),
    }
    return document([dict(prefix=p, **common, **s) for p, s in states.items()])


def dialog():
    m = POPUP_PADDING
    return document([dict(prefix="", w=4 * POPUP_RADIUS, h=4 * POPUP_RADIUS, r=POPUP_RADIUS,
                          fill=SURFACE, margins=(m, m, m, m))])


METADATA = {
    "KPlugin": {
        "Authors": [{"Name": "ZumaOS"}],
        "Description": "Dark shelf and pill buttons from the ZumaOS Figma design",
        "Id": "ZumaOS",
        "License": "GPL-2.0-or-later",
        "Name": "ZumaOS",
        "Version": "1.0",
    },
    "X-Plasma-API": "5.0",
}


def main():
    out = pathlib.Path(sys.argv[1])
    files = {
        "widgets/panel-background.svg": panel(),
        "solid/widgets/panel-background.svg": panel(),
        "widgets/tasks.svg": tasks(),
        "dialogs/background.svg": dialog(),
        "solid/dialogs/background.svg": dialog(),
    }
    for name, svg in files.items():
        path = out / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(svg)
    (out / "metadata.json").write_text(json.dumps(METADATA, indent=4) + "\n")


if __name__ == "__main__":
    main()
