# Render the branding sources (branding/) in a throwaway stage so the final
# image doesn't carry the rendering tools.
FROM registry.fedoraproject.org/fedora:43 AS assets
RUN dnf -y install librsvg2-tools python3 python3-pillow unzip && dnf clean all

# Inter (UI font) isn't packaged for EL10; take the pinned upstream release.
ARG INTER_VERSION=4.1
ARG INTER_SHA256=9883fdd4a49d4fb66bd8177ba6625ef9a64aa45899767dde3d36aa425756b11e
RUN set -eux; \
    curl -fsSLo /tmp/inter.zip \
        https://github.com/rsms/inter/releases/download/v$INTER_VERSION/Inter-$INTER_VERSION.zip; \
    echo "$INTER_SHA256  /tmp/inter.zip" | sha256sum -c; \
    mkdir -p /out/usr/share/fonts/inter /out/usr/share/licenses/inter-fonts; \
    unzip -j /tmp/inter.zip InterVariable.ttf InterVariable-Italic.ttf -d /out/usr/share/fonts/inter; \
    unzip -j /tmp/inter.zip LICENSE.txt -d /out/usr/share/licenses/inter-fonts; \
    rm /tmp/inter.zip

COPY branding/ /src/
RUN /src/render.sh /out

# AppGrid, the Launchpad-style app library (GPL-2.0-or-later, not packaged
# for EL10). Built on the base image so it links against the same Plasma.
FROM quay.io/almalinuxorg/atomic-desktop-kde AS appgrid
RUN dnf -y --enablerepo=crb install \
        cmake extra-cmake-modules gcc-c++ gettext \
        qt6-qtbase-devel qt6-qtdeclarative-devel libplasma-devel \
        kf6-kpackage-devel kf6-kio-devel kf6-kservice-devel kf6-ki18n-devel \
        kf6-kconfig-devel kf6-kcoreaddons-devel kf6-kiconthemes-devel \
        kf6-ksvg-devel kf6-kwindowsystem-devel kf6-kglobalaccel-devel \
        kf6-krunner-devel layer-shell-qt-devel plasma-activities-devel \
        plasma-activities-stats-devel plasma-workspace-devel appstream-qt-devel \
    && dnf clean all

ARG APPGRID_VERSION=1.9.6
ARG APPGRID_SHA256=cdbbc406a446665c36d2c0563d822c5bfa2894c23d094791cc7d18878b5dfd84
RUN set -eux; \
    curl -fsSLo /tmp/appgrid.tar.gz \
        https://github.com/xarbit/plasma6-applet-appgrid/archive/refs/tags/v$APPGRID_VERSION.tar.gz; \
    echo "$APPGRID_SHA256  /tmp/appgrid.tar.gz" | sha256sum -c; \
    mkdir /tmp/appgrid; \
    tar -xzf /tmp/appgrid.tar.gz -C /tmp/appgrid --strip-components=1; \
    cmake -S /tmp/appgrid -B /tmp/build -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_TESTING=OFF; \
    cmake --build /tmp/build -j"$(nproc)"; \
    DESTDIR=/out cmake --install /tmp/build

FROM quay.io/almalinuxorg/atomic-desktop-kde

# Icons and the monospace font come from EPEL.
RUN dnf -y install papirus-icon-theme jetbrains-mono-fonts && dnf clean all

# Rendered logos, wallpapers, window decoration, fonts and Plymouth frames,
# then the hand-written system files (KDE global theme, colour scheme,
# system-wide defaults).
COPY --from=assets /out/ /
COPY --from=appgrid /out/ /
COPY files/ /
RUN fc-cache -f

# Point the upstream Fedora/AlmaLinux logo paths at the ZumaOS logos.
RUN set -eux; \
    logos=/usr/share/zumaos-logos; \
    find /usr/share \( -name 'fedora-logo-icon.png' -o -name 'system-logo-icon.png' \) \
        -exec ln -sf $logos/zumaos-logo.png {} \; ; \
    for f in /usr/share/almalinux-logos/*.svg; do \
        ln -sf $logos/zumaos-logo.svg "$f"; \
    done; \
    find /usr/share/pixmaps \
        \( -name 'fedora-logo-sprite.png' -o -name 'bootlogo_128.png' \
        -o -name 'bootlogo_256.png' \) \
        -exec ln -sf $logos/zumaos-logo.png {} \; ; \
    find /usr/share/pixmaps \
        \( -name 'fedora-logo.png' -o -name 'fedora-logo-small.png' \
        -o -name 'system-logo-white.png' \) \
        -exec ln -sf $logos/zumaos-wordmark.png {} \; ; \
    find /usr/share/pixmaps -name 'fedora-gdm-logo.png' \
        -exec ln -sf $logos/zumaos-wordmark-small.png {} \; ; \
    find /usr/share/pixmaps -name 'fedora-logo-sprite.svg' \
        -exec ln -sf $logos/zumaos-logo.svg {} \; ; \
    ln -sf $logos/zumaos-logo.svg /usr/share/icons/hicolor/scalable/apps/start-here.svg; \
    ln -sf $logos/zumaos-logo.svg /usr/share/icons/hicolor/scalable/apps/zumaos-logo.svg; \
    ln -sf $logos/zumaos-symbolic.svg /usr/share/icons/hicolor/scalable/apps/zumaos-symbolic.svg; \
    ln -sf $logos/zumaos-wordmark.png /usr/share/anaconda/pixmaps/sidebar-logo.png; \
    gtk-update-icon-cache -f -q /usr/share/icons/hicolor

# System Settings becomes plain "Settings" with the ZumaOS icon, opened with
# Meta+I as on Windows. Only the main entry is touched, not its actions;
# translated names go so every language shows the same short name.
RUN set -eux; \
    f=/usr/share/applications/systemsettings.desktop; \
    sed -i \
        -e '/^\[Desktop Entry\]/,/^\[/{/^\(Name\|GenericName\)\[/d}' \
        -e '/^\[Desktop Entry\]/,/^\[/{/^X-KDE-Shortcuts=/d}' \
        -e '/^\[Desktop Entry\]/,/^\[/s/^Name=.*/Name=Settings/' \
        -e '/^\[Desktop Entry\]/,/^\[/s/^Icon=.*/Icon=zumaos-settings/' \
        -e '/^\[Desktop Entry\]/a X-KDE-Shortcuts=Meta+I' \
        "$f"; \
    grep -qx 'Name=Settings' "$f"; \
    grep -qx 'X-KDE-Shortcuts=Meta+I' "$f"

# Settings sidebar categories take their Windows 11 names.
RUN set -eux; \
    cd /usr/share/systemsettings/categories; \
    for entry in \
        'system-administration|System' \
        'hardware|Devices' \
        'network|Network \& internet' \
        'appearance|Personalization' \
        'applications|Apps' \
        'regionalsettings|Time \& language' \
        'security-privacy|Privacy \& security' \
        'workspace|Desktop'; \
    do \
        f=settings-${entry%%|*}.desktop; name=${entry#*|}; \
        sed -i -e '/^Name\[/d' -e "s/^Name=.*/Name=$name/" "$f"; \
        grep -q '^Name=[A-Z]' "$f"; \
    done

# The login screen (Plasma Login Manager) and the distro fallback profile
# use wallpapers/Fedora -> Default; point Default at ZumaOS.
RUN ln -sfn ZumaOS /usr/share/wallpapers/Default

# Boot splash: reuse the stock keyboard-layout images for the disk-unlock
# prompt, then rebuild the initramfs so Plymouth shows the ZumaOS theme.
RUN set -eux; \
    theme=/usr/share/plymouth/themes/zumaos; \
    for f in capslock.png keyboard.png keymap-render.png; do \
        if [ -e /usr/share/plymouth/themes/spinner/$f ]; then \
            cp /usr/share/plymouth/themes/spinner/$f $theme/; \
        fi; \
    done; \
    plymouth-set-default-theme zumaos; \
    kver=$(ls /usr/lib/modules); \
    dracut --no-hostonly --kver "$kver" --reproducible --add ostree \
        -f "/usr/lib/modules/$kver/initramfs.img"

RUN set -eux; \
    f=/usr/lib/os-release; \
    sed -i \
        -e 's/^NAME="AlmaLinux"/NAME="ZumaOS"/' \
        -e 's/^PRETTY_NAME="AlmaLinux /PRETTY_NAME="ZumaOS /' \
        -e 's/^ID="almalinux"/ID="zumaos"/' \
        -e 's/^ID_LIKE="rhel centos fedora"/ID_LIKE="almalinux rhel centos fedora"/' \
        -e 's/^VENDOR_NAME="AlmaLinux"/VENDOR_NAME="ZumaOS"/' \
        -e 's/10\.2/10/g' \
        -e 's/ ([^)]*)"/"/g' \
        -e 's#^\(HOME_URL\|DOCUMENTATION_URL\|VENDOR_URL\|BUG_REPORT_URL\)="https://[^"]*"#\1="https://example.com/"#' \
        -e 's#cpe:/o:almalinux:almalinux:#cpe:/o:zumaos:zumaos:#' \
        -e 's/^ALMALINUX_/ZUMAOS_/' \
        -e 's/^ZUMAOS_MANTISBT_PROJECT="AlmaLinux-10"/ZUMAOS_MANTISBT_PROJECT="ZumaOS-10"/' \
        -e 's/^REDHAT_SUPPORT_PRODUCT="AlmaLinux"/REDHAT_SUPPORT_PRODUCT="ZumaOS"/' \
        -e '/^VARIANT_ID=/d' \
        "$f"
