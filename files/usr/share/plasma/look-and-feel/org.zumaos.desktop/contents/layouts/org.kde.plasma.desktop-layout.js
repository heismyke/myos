// ZumaOS first-login layout: the ZumaOS wallpaper and a single floating,
// centred, translucent dock so the KWin blur gives the glass look.
var wallpaper = "file:///usr/share/wallpapers/ZumaOS/contents/images/3840x2160.png";

var desktopsArray = desktopsForActivity(currentActivity());
for (var i = 0; i < desktopsArray.length; i++) {
    var desktop = desktopsArray[i];
    desktop.wallpaperPlugin = "org.kde.image";
    desktop.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    desktop.writeConfig("Image", wallpaper);
}

var panel = new Panel;
panel.location = "bottom";
panel.height = 2 * Math.ceil(gridUnit * 2.75 / 2);
panel.floating = true;
panel.alignment = "center";
panel.lengthMode = "fit";
panel.opacity = "translucent";

var kickoff = panel.addWidget("org.kde.plasma.kickoff");
kickoff.currentConfigGroup = ["General"];
kickoff.writeConfig("icon", "/usr/share/zumaos-logos/zumaos-logo.svg");

var tasks = panel.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", ["preferred://filemanager", "preferred://browser",
                                "applications:org.kde.konsole.desktop",
                                "applications:org.kde.discover.desktop"]);

panel.addWidget("org.kde.plasma.marginsseparator");
panel.addWidget("org.kde.plasma.systemtray");
panel.addWidget("org.kde.plasma.digitalclock");
