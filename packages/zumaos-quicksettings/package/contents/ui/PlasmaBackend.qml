import QtQuick
import org.kde.bluezqt as BluezQt
import org.kde.kcmutils as KCMUtils
import org.kde.ksysguard.sensors as Sensors
import org.kde.notificationmanager as NotificationManager
import org.kde.plasma.networkmanagement as PlasmaNM
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.private.battery as BatteryControl
import org.kde.plasma.private.batterymonitor as Battery
import org.kde.plasma.private.brightnesscontrolplugin as Brightness
import org.kde.plasma.private.sessions as Sessions
import org.kde.plasma.private.volume as Volume

// Binds QuickSettingsView to Plasma's own services. Mirrors the property and
// function names of dev/preview/DesignBackend.qml.
//
// Several imports are Plasma-private (org.kde.plasma.private.*) and change
// between Plasma releases; this file targets Plasma 6.3 (Debian 13). Keep
// every Plasma-version-specific call in this file.
QtObject {
    id: backend

    // Settings the applet passes in.
    property string lightColorScheme: "BreezeLight"
    property string darkColorScheme: "ZumaOS"
    signal configureRequested()

    // Network (NetworkManager via plasma-nm)
    readonly property bool wifiEnabled: enabledConnections.wirelessEnabled
    readonly property string networkTitle: qsTr("Internet")
    readonly property string networkSubtitle: {
        // With networking off (or NetworkManager not running) activeConnections
        // holds a status sentence rather than connections.
        if (!enabledConnections.networkingEnabled)
            return qsTr("Off");
        // Otherwise it is "Name: state" lines; show the first name.
        const first = networkStatus.activeConnections.split("\n")[0] || "";
        const name = first.split(":")[0].trim();
        return name || (wifiEnabled ? qsTr("Not connected") : qsTr("Off"));
    }

    // Shelf network glyph. NetworkManager::Connectivity: 3 Limited, 4 Full.
    readonly property bool networkConnected: enabledConnections.networkingEnabled
        && networkStatus.connectivity >= 3

    // Bluetooth (BlueZ)
    readonly property bool bluetoothEnabled: BluezQt.Manager.bluetoothOperational
    readonly property string bluetoothTitle: {
        const devices = BluezQt.Manager.connectedDevices;
        return devices.length > 0 ? devices[0].name : qsTr("Bluetooth");
    }

    // Power profiles (power-profiles-daemon via PowerDevil)
    readonly property bool batterySaver: powerProfiles.activeProfile === "power-saver"

    // Colour scheme
    property bool darkMode: true

    // CPU temperature (ksystemstats)
    readonly property string temperature: temperatureSensor.formattedValue || "–"

    // Audio (PipeWire via plasma-pa)
    readonly property bool volumeAvailable: Volume.PreferredDevice.sink !== null
    readonly property real volume: volumeAvailable
        ? Math.min(1, Volume.PreferredDevice.sink.volume / Volume.PulseAudio.NormalVolume) : 0
    readonly property bool micMuted: Volume.PreferredDevice.source ? Volume.PreferredDevice.source.muted : true

    // Screen brightness (PowerDevil); the first display is used.
    readonly property QtObject display: displays.count > 0 ? displays.objectAt(0) : null
    readonly property bool brightnessAvailable: brightnessControl.isBrightnessAvailable && display !== null
    readonly property real brightness: display && display.maxBrightness > 0
        ? display.brightness / display.maxBrightness : 0

    // Battery (UPower via Solid)
    readonly property bool hasBattery: batteryModel.hasInternalBatteries
    readonly property bool charging: batteryModel.state === BatteryControl.BatteryControlModel.Charging
    readonly property string batteryText: {
        if (!batteryModel.hasCumulative)
            return "";
        const parts = [batteryModel.percent + "%"];
        const ms = batteryModel.smoothedRemainingMsec;
        if (ms > 0 && batteryModel.state === BatteryControl.BatteryControlModel.Discharging) {
            const minutes = Math.round(ms / 60000);
            parts.push(qsTr("%1h%2 Left").arg(Math.floor(minutes / 60))
                       .arg(String(minutes % 60).padStart(2, "0")));
        }
        return parts.join(" • ");
    }

    // Notifications: one icon per app with something pending.
    readonly property var notificationIcons: {
        const seen = new Set(), icons = [];
        for (let i = 0; i < notificationIconItems.count; ++i) {
            const n = notificationIconItems.objectAt(i);
            if (!n || !n.icon || seen.has(n.icon))
                continue;
            seen.add(n.icon);
            icons.push({ icon: n.icon, name: n.name });
        }
        return icons;
    }

    function setWifiEnabled(on) { nmHandler.enableWireless(on); }

    function setBluetoothEnabled(on) {
        BluezQt.Manager.bluetoothBlocked = !on;
        for (const adapter of BluezQt.Manager.adapters)
            adapter.powered = on;
    }

    function setBatterySaver(on) {
        powerProfiles.setProfile(on ? "power-saver"
                                    : (powerProfiles.configuredProfile || "balanced"));
    }

    function setDarkMode(on) {
        darkMode = on;
        run(["plasma-apply-colorscheme", on ? darkColorScheme : lightColorScheme]);
    }

    function setMicMuted(on) {
        if (Volume.PreferredDevice.source)
            Volume.PreferredDevice.source.muted = on;
    }

    function setVolume(v) {
        const sink = Volume.PreferredDevice.sink;
        if (!sink)
            return;
        sink.volume = Math.round(v * Volume.PulseAudio.NormalVolume);
        if (sink.muted && v > 0)
            sink.muted = false;
    }

    function setBrightness(v) {
        if (display)
            brightnessControl.setBrightness(display.displayName, Math.round(v * display.maxBrightness));
    }

    function clearNotifications() {
        notifications.clear(NotificationManager.Notifications.ClearExpired);
    }

    function openNotifications() { openSettings("kcm_notifications"); }

    function openSettings(kcm) {
        if (kcm)
            KCMUtils.KCMLauncher.openSystemSettings(kcm);
        else
            run(["systemsettings"]);
    }

    function openSystemMonitor() { run(["plasma-systemmonitor"]); }
    function captureScreen() { run(["spectacle", "--region"]); }
    function requestShutdown() { session.requestShutdown(); }
    function requestLogout() { session.requestLogout(); }
    function editTiles() { configureRequested(); }

    function run(argv) {
        // The executable engine takes a shell command line; quote each word.
        executable.connectSource(argv.map(a => "'" + a.replace(/'/g, "'\\''") + "'").join(" "));
    }

    property list<QtObject> data: [
        PlasmaNM.NetworkStatus { id: networkStatus },
        PlasmaNM.EnabledConnections { id: enabledConnections },
        PlasmaNM.Handler { id: nmHandler },

        Battery.PowerProfilesControl { id: powerProfiles },
        BatteryControl.BatteryControlModel { id: batteryModel },

        Brightness.ScreenBrightnessControl { id: brightnessControl },
        Instantiator {
            id: displays
            model: brightnessControl.displays
            delegate: QtObject {
                required property string displayName
                required property int brightness
                required property int maxBrightness
            }
        },

        Sensors.Sensor {
            id: temperatureSensor
            sensorId: "cpu/all/averageTemperature"
        },

        Sessions.SessionManagement { id: session },

        NotificationManager.Notifications {
            id: notifications
            showExpired: true
            showDismissed: true
            showJobs: false
            groupMode: NotificationManager.Notifications.GroupApplicationsFlat
        },
        Instantiator {
            id: notificationIconItems
            model: notifications
            delegate: QtObject {
                required property var model
                readonly property string icon: model.applicationIconName || ""
                readonly property string name: model.applicationName || ""
            }
        },

        P5Support.DataSource {
            id: executable
            engine: "executable"
            onNewData: (source, data) => {
                if (source === readScheme) {
                    // Unset means Plasma's default, Breeze Light.
                    const scheme = (data.stdout || "").trim() || "BreezeLight";
                    backend.darkMode = scheme === backend.darkColorScheme || /dark/i.test(scheme);
                }
                disconnectSource(source);
            }
            readonly property string readScheme: "kreadconfig6 --group General --key ColorScheme"
            Component.onCompleted: connectSource(readScheme)
        }
    ]
}
