# ZumaOS

A minimal, glass-styled desktop OS for Africa, built as a bootable container
on [AlmaLinux Atomic KDE](https://github.com/AlmaLinux/atomic-desktop).

## Layout

| Path | What it is |
| --- | --- |
| `Containerfile` | The image build. |
| `branding/` | Sources rendered in a throwaway build stage by `render.sh`: the logo and wordmark (from zumaos.com), the top-bar rock glyph, wallpapers, boot-splash parts, and `aurorae/make-theme.py`, which generates the traffic-light window decoration. |
| `files/` | Copied over `/` in the image: KDE global theme (`org.zumaos.desktop`), the `ZumaOS` colour scheme, Plymouth theme, and system-wide defaults in `/etc/xdg`. |
| `iso-hook.sh` | Writes the Anaconda installer product name. |

## Look

macOS-inspired, in the zumaos.com brand:

- **Palette:** near-black greys with the zumaos.com violet `#A855F7` accent.
- **Layout:** a slim translucent menu bar (Zuma menu, the active app's global menu, tray, clock) and a floating glass dock at the bottom.
- **Windows:** `ZumaOS` Aurorae decoration with red/yellow/green buttons on the left, rounded top corners, soft shadows; magic-lamp minimise.
- **Glass:** KWin blur and background contrast on by default.
- **Fonts / icons:** Inter (pinned upstream release), JetBrains Mono, Papirus-Dark.
- **Wallpaper:** Zuma Rock photos; `ZumaOS` switches between day and night with the colour scheme, plus `ZumaOS Moonrise`.
- **Search:** KRunner floats in the middle of the screen, like Spotlight.
- **Boot / login splash:** the wordmark on black with a slim progress bar.

KDE defaults in `/etc/xdg` only seed new accounts; users can still change them.

## Build

```sh
podman build -t zumaos .
# or, with Docker (it only auto-detects a file named Dockerfile):
docker build -f Containerfile -t zumaos .
```

CI builds the image on every push to `main`; run the workflow manually to also build an ISO.
