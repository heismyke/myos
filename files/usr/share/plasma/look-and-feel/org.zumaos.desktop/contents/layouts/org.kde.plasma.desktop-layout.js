// ZumaOS first-login layout, from the Figma shelf (node 1:16858): one dark bar
// along the bottom with the launcher on the left, and the pinned and running
// apps, date and time, status and Overview buttons on the right.
var wallpaper = "file:///usr/share/wallpapers/ZumaOS/";

var desktopsArray = desktopsForActivity(currentActivity());
for (var i = 0; i < desktopsArray.length; i++) {
    var desktop = desktopsArray[i];
    desktop.wallpaperPlugin = "org.kde.image";
    desktop.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    desktop.writeConfig("Image", wallpaper);
}

var shelf = new Panel;
shelf.location = "bottom";
shelf.height = 56;
// The ZumaOS Plasma theme gives floating panels no gap, so the shelf still
// sits on the screen edge; floating keeps its rounded top corners drawn.
shelf.floating = true;
shelf.opacity = "opaque";

// Launcher: AppGrid's panel popup, with search on top, pinned apps, recent
// apps and the power buttons. Kickoff stands in where AppGrid isn't built
// (the Debian dev image).
var hasAppGrid = knownWidgetTypes.indexOf("dev.xarbit.appgrid.panel") !== -1;
var launcher = shelf.addWidget(hasAppGrid ? "dev.xarbit.appgrid.panel" : "org.kde.plasma.kickoff");
launcher.currentConfigGroup = ["General"];
launcher.writeConfig("icon", "zumaos-launcher");
if (hasAppGrid) {
    launcher.writeConfig("startWithFavorites", true);
    launcher.writeConfig("showCategoryBar", false);
    launcher.writeConfig("gridColumns", 6);
    launcher.writeConfig("gridRows", 3);
    launcher.writeConfig("overrideRadius", true);
    launcher.writeConfig("cornerRadius", 24); // the ZumaOS theme's popup corners
    launcher.writeConfig("favoriteApps", ["org.kde.dolphin.desktop", "org.kde.discover.desktop",
                                          "org.kde.konsole.desktop", "org.kde.kwrite.desktop",
                                          "systemsettings.desktop"]);
}

shelf.addWidget("org.kde.plasma.panelspacer");

// Pinned and running apps; the theme draws each as a grey circle.
var apps = shelf.addWidget("org.kde.plasma.icontasks");
apps.currentConfigGroup = ["General"];
apps.writeConfig("launchers", ["preferred://filemanager", "preferred://browser",
                               "applications:org.kde.discover.desktop",
                               "applications:systemsettings.desktop"]);

// Apps' own tray icons. Network, sound, battery, Bluetooth, brightness and
// notifications are in Quick Settings, so their tray entries stay hidden
// (the notifications one still has to load: it shows the popups).
var tray = shelf.addWidget("org.kde.plasma.systemtray");
var trayContainment = desktopById(tray.readConfig("SystrayContainmentId"));
if (trayContainment) {
    trayContainment.currentConfigGroup = ["General"];
    trayContainment.writeConfig("hiddenItems", ["org.kde.plasma.networkmanagement",
        "org.kde.plasma.volume", "org.kde.plasma.battery", "org.kde.plasma.bluetooth",
        "org.kde.plasma.brightness", "org.kde.plasma.notifications"]);
}

shelf.addWidget("org.zumaos.clock");
shelf.addWidget("org.zumaos.quicksettings");
shelf.addWidget("org.zumaos.overview");
