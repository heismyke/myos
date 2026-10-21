// ZumaOS first-login layout, modelled on macOS: a slim translucent menu bar
// across the top (Zuma menu, the active app's menus, tray, clock) and a
// floating glass dock at the bottom. KWin's blur gives both the glass look.
var wallpaper = "file:///usr/share/wallpapers/ZumaOS/";

var desktopsArray = desktopsForActivity(currentActivity());
for (var i = 0; i < desktopsArray.length; i++) {
    var desktop = desktopsArray[i];
    desktop.wallpaperPlugin = "org.kde.image";
    desktop.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    desktop.writeConfig("Image", wallpaper);
}

// Menu bar
var menuBar = new Panel;
menuBar.location = "top";
menuBar.height = 2 * Math.ceil(gridUnit * 1.5 / 2);
menuBar.floating = false;
menuBar.opacity = "translucent";

var zumaMenu = menuBar.addWidget("org.kde.plasma.kickoff");
zumaMenu.currentConfigGroup = ["General"];
zumaMenu.writeConfig("icon", "/usr/share/zumaos-logos/zumaos-symbolic.svg");

menuBar.addWidget("org.kde.plasma.appmenu");
menuBar.addWidget("org.kde.plasma.panelspacer");
menuBar.addWidget("org.kde.plasma.systemtray");

var clock = menuBar.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", true);
clock.writeConfig("dateFormat", "custom");
clock.writeConfig("customDateFormat", "ddd d MMM");
clock.writeConfig("dateDisplayFormat", 1); // date beside the time

// Dock
var dock = new Panel;
dock.location = "bottom";
dock.height = 2 * Math.ceil(gridUnit * 3.5 / 2);
dock.floating = true;
dock.alignment = "center";
dock.lengthMode = "fit";
dock.opacity = "translucent";

var apps = dock.addWidget("org.kde.plasma.icontasks");
apps.currentConfigGroup = ["General"];
apps.writeConfig("launchers", ["preferred://filemanager", "preferred://browser",
                               "applications:org.kde.discover.desktop",
                               "applications:org.kde.konsole.desktop",
                               "applications:systemsettings.desktop"]);

dock.addWidget("org.kde.plasma.marginsseparator");
dock.addWidget("org.kde.plasma.trash");
