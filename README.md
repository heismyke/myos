# ZumaOS

A minimal, glass-styled desktop OS for Africa, built as a bootable container
on [AlmaLinux Atomic KDE](https://github.com/AlmaLinux/atomic-desktop).

## Layout

| Path | What it is |
| --- | --- |
| `Containerfile` | The image build. |
| `branding/` | Sources rendered in a throwaway build stage by `render.sh`: the logo and wordmark (from zumaos.com), the monochrome rock glyph, the Settings icon, wallpapers, boot-splash parts, and `aurorae/make-theme.py`, which generates the Windows 11-style window decoration. |
| `files/` | Copied over `/` in the image: KDE global theme (`org.zumaos.desktop`), the `ZumaOS` colour scheme, Plymouth theme, system-wide defaults in `/etc/xdg`, and the new-account desktop in `/etc/skel`. |
| `iso-hook.sh` | Writes the Anaconda installer product name. |

## Look

Windows 11-inspired, in the zumaos.com brand:

- **Palette:** near-black greys with the zumaos.com violet `#A855F7` accent.
- **Taskbar:** one translucent bar along the bottom, with Start and the app icons centred and the tray, clock and show-desktop strip on the right.
- **Start:** the ZumaOS logo opens [AppGrid](https://github.com/xarbit/plasma6-applet-appgrid)'s panel popup: search, pinned apps, recent apps and power buttons. It isn't packaged for EL10, so the image builds it from a pinned, checksummed release.
- **Windows:** `ZumaOS` Aurorae decoration with the app icon and a left-aligned title, Windows 11-style minimise/maximise/close buttons on the right (close turns red), rounded top corners and soft shadows. The title bar takes the app's header colour, so it and the toolbar read as one surface, like Mica.
- **Settings:** called "Settings", with its own icon and Windows 11 category names (System, Devices, Network & internet, Personalization, Apps, Time & language, Privacy & security). Technical pages, and ones that would undo the ZumaOS look, are hidden in `/etc/xdg/kdeglobals`.
- **Shortcuts:** Meta opens Start, Meta+I opens Settings, and Alt+Tab shows a grid of window thumbnails.
- **Desktop:** a Trash icon, like the Recycle Bin.
- **Glass:** KWin blur and background contrast on by default.
- **Fonts / icons:** Inter (pinned upstream release), JetBrains Mono, Papirus-Dark.
- **Wallpaper:** Zuma Rock photos; `ZumaOS` switches between day and night with the colour scheme, plus `ZumaOS Moonrise`.
- **Search:** KRunner floats in the middle of the screen.
- **Boot / login splash:** the wordmark on black with a slim progress bar.

KDE defaults in `/etc/xdg` only seed new accounts; users can still change them.

## Build

```sh
podman build -t zumaos .
# or, with Docker (it only auto-detects a file named Dockerfile):
docker build -f Containerfile -t zumaos .
```

CI builds the image on every push to `main`; run the workflow manually to also build an ISO.
