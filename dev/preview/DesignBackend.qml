import QtQuick

// The state shown in Figma 1:6291, so the preview renders the design frame.
// Actions only update local state and log, so interactions can be tried.
QtObject {
    property bool wifiEnabled: true
    property string networkTitle: "Internet"
    property string networkSubtitle: "NAME"
    property bool bluetoothEnabled: true
    property string bluetoothTitle: "J Buds Lite 2"
    property bool batterySaver: false
    property bool darkMode: false
    property string temperature: "36°"
    property bool micMuted: false
    property bool volumeAvailable: true
    // Slider fills measured from the frame: 369 of 388px and 357 of 448px.
    property real volume: 0.944
    property bool brightnessAvailable: true
    property real brightness: 0.7725
    property string batteryText: "97% • 5h32 Left"
    property bool hasBattery: true
    property bool charging: true
    property bool networkConnected: true
    property var notificationIcons: [
        { icon: "local_mall", name: "Store" },
        { icon: "auto_awesome", name: "Assistant" },
        { icon: "browser_updated", name: "Updates" }
    ]

    function setWifiEnabled(on) { wifiEnabled = on; console.log("wifi", on) }
    function setBluetoothEnabled(on) { bluetoothEnabled = on; console.log("bluetooth", on) }
    function setBatterySaver(on) { batterySaver = on; console.log("battery saver", on) }
    function setDarkMode(on) { darkMode = on; console.log("dark mode", on) }
    function setMicMuted(on) { micMuted = on; console.log("mic muted", on) }
    function setVolume(v) { volume = v; console.log("volume", v) }
    function setBrightness(v) { brightness = v; console.log("brightness", v) }
    function clearNotifications() { notificationIcons = []; console.log("clear notifications") }
    function openNotifications() { console.log("open notifications") }
    function openSettings(kcm) { console.log("open settings", kcm) }
    function openSystemMonitor() { console.log("open system monitor") }
    function captureScreen() { console.log("capture screen") }
    function requestShutdown() { console.log("shutdown") }
    function requestLogout() { console.log("logout") }
    function editTiles() { console.log("edit tiles") }
}
