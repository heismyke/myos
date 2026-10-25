// ZumaOS first-login layout, modelled on Windows 11: one taskbar along the
// bottom with Start and the app icons centred, and the tray and clock on the
// right. KWin's blur gives the taskbar its glass look.
var wallpaper = "file:///usr/share/wallpapers/ZumaOS/";

var desktopsArray = desktopsForActivity(currentActivity());
for (var i = 0; i < desktopsArray.length; i++) {
    var desktop = desktopsArray[i];
    desktop.wallpaperPlugin = "org.kde.image";
    desktop.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    desktop.writeConfig("Image", wallpaper);
}

var taskbar = new Panel;
taskbar.location = "bottom";
taskbar.height = 2 * Math.ceil(gridUnit * 3 / 2);
taskbar.floating = false;
taskbar.opacity = "translucent";

// Spacers either side keep Start and the apps in the middle.
taskbar.addWidget("org.kde.plasma.panelspacer");

// Start: the ZumaOS logo opens AppGrid's panel popup, with search on top,
// pinned apps, recent apps and the power buttons.
var start = taskbar.addWidget("dev.xarbit.appgrid.panel");
start.currentConfigGroup = ["General"];
start.writeConfig("icon", "zumaos-logo");
start.writeConfig("startWithFavorites", true);
start.writeConfig("showCategoryBar", false);
start.writeConfig("gridColumns", 6);
start.writeConfig("gridRows", 3);
start.writeConfig("overrideRadius", true);
start.writeConfig("cornerRadius", 8); // Windows 11 corners, not AppGrid's 24
start.writeConfig("favoriteApps", ["org.kde.dolphin.desktop", "org.kde.discover.desktop",
                                   "org.kde.konsole.desktop", "org.kde.kwrite.desktop",
                                   "systemsettings.desktop"]);

var apps = taskbar.addWidget("org.kde.plasma.icontasks");
apps.currentConfigGroup = ["General"];
apps.writeConfig("launchers", ["preferred://filemanager", "preferred://browser",
                               "applications:org.kde.discover.desktop",
                               "applications:systemsettings.desktop"]);

taskbar.addWidget("org.kde.plasma.panelspacer");
taskbar.addWidget("org.kde.plasma.systemtray");

var clock = taskbar.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", true);
clock.writeConfig("dateDisplayFormat", 2); // date under the time

// Show desktop, the thin strip at the far right.
taskbar.addWidget("org.kde.plasma.showdesktop");
