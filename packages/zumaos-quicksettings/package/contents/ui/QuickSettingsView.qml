import QtQuick
import QtQuick.Layouts
import org.zumaos.style

// Quick Settings panel, Figma "Frame 49/Default" (1:6291): a notification
// strip above the tiles, sliders and session buttons. Knows nothing about
// Plasma; everything comes from `backend` (PlasmaBackend.qml in the applet,
// a fixed one in the preview).
Item {
    id: view

    required property QtObject backend
    // Tile ids in display order. Wide tiles take half a row, compact ones a
    // quarter (screenCapture, keyboard).
    property var tiles: ["network", "bluetooth", "batterySaver", "darkMode",
                         "accessibility", "screenCapture", "keyboard"]
    property int rowsPerPage: 4

    signal closeRequested()

    readonly property var compactTiles: ["screenCapture", "keyboard"]
    readonly property int unitWidth: (Tokens.panelContentWidth - 3 * Tokens.spacingXs) / 4

    // Pack tiles into rows of four units, then rows into pages.
    readonly property var pages: {
        const rows = [];
        let row = [], used = 0;
        for (const id of tiles) {
            if (!(id in specs)) continue;
            const units = compactTiles.includes(id) ? 1 : 2;
            if (used + units > 4) { rows.push(row); row = []; used = 0; }
            row.push(id);
            used += units;
        }
        if (row.length) rows.push(row);
        const result = [];
        for (let i = 0; i < rows.length; i += rowsPerPage)
            result.push(rows.slice(i, i + rowsPerPage));
        return result.length ? result : [[]];
    }

    readonly property var specs: ({
        network: {
            icon: "network_wifi", title: backend.networkTitle,
            subtitle: backend.networkSubtitle, active: backend.wifiEnabled, details: true
        },
        bluetooth: {
            icon: "bluetooth_connected", title: backend.bluetoothTitle,
            subtitle: backend.bluetoothEnabled ? qsTr("On") : qsTr("Off"),
            active: backend.bluetoothEnabled, details: true
        },
        batterySaver: {
            icon: "battery_saver", title: qsTr("Battery Saver"),
            subtitle: backend.batterySaver ? qsTr("On") : qsTr("Off"),
            active: backend.batterySaver
        },
        darkMode: {
            icon: "contrast", title: qsTr("Dark Mode"),
            subtitle: backend.darkMode ? qsTr("On") : qsTr("Off"),
            active: backend.darkMode
        },
        temperature: {
            icon: "thermostat", title: qsTr("Temperature"),
            subtitle: backend.temperature
        },
        micAccess: {
            icon: "keyboard_voice", title: qsTr("Mic Access"),
            subtitle: backend.micMuted ? qsTr("Blocked") : qsTr("Available"),
            muted: true
        },
        accessibility: { icon: "accessibility_new", title: qsTr("Accessibility"), details: true },
        screenCapture: { icon: "center_focus_weak", title: qsTr("Screen Capture"), compact: true },
        keyboard: { icon: "keyboard", title: qsTr("Keyboard"), compact: true }
    })

    function activate(id) {
        switch (id) {
        case "network": backend.setWifiEnabled(!backend.wifiEnabled); break;
        case "bluetooth": backend.setBluetoothEnabled(!backend.bluetoothEnabled); break;
        case "batterySaver": backend.setBatterySaver(!backend.batterySaver); break;
        case "darkMode": backend.setDarkMode(!backend.darkMode); break;
        case "temperature": backend.openSystemMonitor(); closeRequested(); break;
        case "micAccess": backend.setMicMuted(!backend.micMuted); break;
        case "accessibility": backend.openSettings("kcm_access"); closeRequested(); break;
        case "screenCapture": closeRequested(); backend.captureScreen(); break;
        case "keyboard": backend.openSettings("kcm_keyboard"); closeRequested(); break;
        }
    }

    function details(id) {
        const kcm = { network: "kcm_networkmanagement", bluetooth: "kcm_bluetooth",
                      accessibility: "kcm_access" }[id];
        backend.openSettings(kcm);
        closeRequested();
    }

    implicitWidth: column.implicitWidth + 2 * column.anchors.margins
    implicitHeight: column.implicitHeight + 2 * column.anchors.margins

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.margins: Tokens.spacingXs
        spacing: Tokens.spacingMd

        // Notification strip (1:16731): app icons of pending notifications.
        ZSurface {
            visible: backend.notificationIcons.length > 0
            Layout.preferredWidth: Tokens.panelContentWidth + 2 * padding

            RowLayout {
                width: Tokens.panelContentWidth
                spacing: Tokens.spacingSm

                Row {
                    Layout.fillWidth: true
                    spacing: Tokens.spacingXs
                    Repeater {
                        model: backend.notificationIcons.slice(0, 8)
                        ZIconButton {
                            required property var modelData
                            iconName: modelData.icon
                            text: modelData.name
                            onClicked: backend.openNotifications()
                        }
                    }
                }

                ZPillButton {
                    text: qsTr("Clear all")
                    onClicked: backend.clearNotifications()
                }
            }
        }

        // Quick Settings (1:16748).
        ZSurface {
            Layout.preferredWidth: Tokens.panelContentWidth + 2 * padding

            ColumnLayout {
                width: Tokens.panelContentWidth
                spacing: Tokens.spacingXl

                // Tiles and page dots (1:16749).
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacingXs

                    ListView {
                        id: pager
                        Layout.fillWidth: true
                        Layout.preferredHeight: contentItem.childrenRect.height
                        orientation: ListView.Horizontal
                        snapMode: ListView.SnapOneItem
                        highlightRangeMode: ListView.StrictlyEnforceRange
                        boundsBehavior: Flickable.StopAtBounds
                        clip: true
                        interactive: count > 1
                        model: view.pages

                        delegate: Column {
                            required property var modelData
                            width: pager.width
                            spacing: Tokens.spacingXs

                            Repeater {
                                model: modelData
                                Row {
                                    required property var modelData
                                    spacing: Tokens.spacingXs

                                    Repeater {
                                        model: modelData
                                        ZTile {
                                            required property string modelData
                                            readonly property var spec: view.specs[modelData]
                                            width: spec.compact ? view.unitWidth
                                                               : 2 * view.unitWidth + Tokens.spacingXs
                                            iconName: spec.icon
                                            title: spec.title
                                            subtitle: spec.subtitle || ""
                                            active: !!spec.active
                                            muted: !!spec.muted
                                            hasDetails: !!spec.details
                                            compact: !!spec.compact
                                            onClicked: view.activate(modelData)
                                            onDetailsClicked: view.details(modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    ZPageIndicator {
                        Layout.alignment: Qt.AlignHCenter
                        count: pager.count
                        currentIndex: pager.currentIndex
                    }
                }

                // Sliders (1:16816).
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacingXs

                    RowLayout {
                        spacing: Tokens.spacingMd
                        ZSlider {
                            Layout.fillWidth: true
                            iconName: "volume_up"
                            Accessible.name: qsTr("Volume")
                            enabled: backend.volumeAvailable
                            value: backend.volume
                            onMoved: backend.setVolume(value)
                        }
                        ZIconButton {
                            size: Tokens.iconSize + 2 * Tokens.spacingMd
                            iconName: "chevron_right"
                            text: qsTr("Audio devices")
                            onClicked: { backend.openSettings("kcm_pulseaudio"); view.closeRequested(); }
                        }
                    }

                    ZSlider {
                        Layout.fillWidth: true
                        visible: backend.brightnessAvailable
                        iconName: "brightness_6"
                        Accessible.name: qsTr("Brightness")
                        value: backend.brightness
                        onMoved: backend.setBrightness(value)
                    }
                }

                // Session and settings buttons (1:16834).
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacingSm

                    Row {
                        Layout.fillWidth: true
                        spacing: Tokens.spacingLg
                        ZIconButton {
                            outlined: true; iconName: "mode_off_on"; text: qsTr("Shut down")
                            onClicked: { view.closeRequested(); backend.requestShutdown(); }
                        }
                        ZIconButton {
                            outlined: true; iconName: "logout"; text: qsTr("Log out")
                            onClicked: { view.closeRequested(); backend.requestLogout(); }
                        }
                        ZIconButton {
                            outlined: true; iconName: "edit"; text: qsTr("Edit tiles")
                            onClicked: { view.closeRequested(); backend.editTiles(); }
                        }
                        ZIconButton {
                            outlined: true; iconName: "settings"; text: qsTr("Settings")
                            onClicked: { view.closeRequested(); backend.openSettings(""); }
                        }
                    }

                    ZIconButton {
                        outlined: true; iconName: "chevron_right"; iconRotation: 90
                        text: qsTr("Close")
                        onClicked: view.closeRequested()
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    visible: backend.batteryText.length > 0
                    text: backend.batteryText
                    color: Tokens.content
                    font.family: Tokens.fontFamily
                    font.pixelSize: Tokens.fontSize
                    font.weight: Tokens.weightBody
                }
            }
        }
    }
}
