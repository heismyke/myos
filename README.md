# ZumaOS

A minimal, glass-styled desktop OS for Africa, built as a bootable container
on [AlmaLinux Atomic KDE](https://github.com/AlmaLinux/atomic-desktop).

## Layout

| Path | What it is |
| --- | --- |
| `Containerfile` | The image build. |
| `branding/` | SVG sources (logo, wordmark, wallpaper, boot-splash parts) and `render.sh`, which turns them into PNGs in a throwaway build stage. Edit the SVGs to rebrand. |
| `files/` | Copied over `/` in the image: KDE global theme (`org.zumaos.desktop`), the `ZumaOS` colour scheme, Plymouth theme, and system-wide defaults in `/etc/xdg`. |
| `iso-hook.sh` | Writes the Anaconda installer product name. |

## Look

- **Palette:** night indigo `#0B1020` / `#151B33`, sunset accent `#F28C38`, teal links `#4FD1C5`.
- **Glass:** KWin blur and background contrast are on by default; the panel is a single floating, centred, translucent dock over a colour-field wallpaper so the blur has something to frost.
- **Boot:** Plymouth `zumaos` theme (two-step plugin): logo on a gradient with an orange arc spinner and a glass password pill.
- **Login splash:** QML splash in the global theme with a glass progress pill.

KDE defaults in `/etc/xdg` only seed new accounts; users can still change them.

## Build

```sh
podman build -t zumaos .
# or, with Docker (it only auto-detects a file named Dockerfile):
docker build -f Containerfile -t zumaos .
```

CI builds the image on every push to `main`; run the workflow manually to also build an ISO.
