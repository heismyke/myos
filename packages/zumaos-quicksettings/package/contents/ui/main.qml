import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.zumaos.style

PlasmoidItem {
    id: root

    Plasmoid.title: qsTr("Quick Settings")
    // The view draws its own Figma cards.
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    toolTipMainText: Plasmoid.title
    toolTipSubText: plasmaBackend.batteryText || plasmaBackend.networkSubtitle

    PlasmaBackend {
        id: plasmaBackend
        lightColorScheme: Plasmoid.configuration.lightColorScheme
        darkColorScheme: Plasmoid.configuration.darkColorScheme
        onConfigureRequested: Plasmoid.internalAction("configure").trigger()
    }

    // Shelf status (Figma 1:16886): notification app icons in one pill, then
    // battery and network in the other. Either opens Quick Settings.
    compactRepresentation: Row {
        spacing: Tokens.segmentGap

        Layout.minimumWidth: implicitWidth
        Layout.preferredWidth: implicitWidth
        Layout.maximumWidth: implicitWidth

        ZPillSegment {
            anchors.verticalCenter: parent.verticalCenter
            edge: Qt.AlignLeft
            text: qsTr("Notifications")
            onClicked: root.expanded = !root.expanded

            // With nothing pending, the design's settings glyph stands in.
            Repeater {
                model: plasmaBackend.notificationIcons.length > 0
                    ? plasmaBackend.notificationIcons.slice(0, 3).map(n => n.icon) : ["settings"]
                ZIcon {
                    required property string modelData
                    name: modelData
                }
            }
        }

        ZPillSegment {
            anchors.verticalCenter: parent.verticalCenter
            edge: Qt.AlignRight
            text: [plasmaBackend.batteryText, plasmaBackend.networkSubtitle].filter(t => t).join(", ")
            onClicked: root.expanded = !root.expanded

            ZIcon {
                visible: plasmaBackend.hasBattery
                name: plasmaBackend.charging ? "battery_charging_full" : "battery_full"
            }
            ZIcon {
                name: plasmaBackend.networkConnected ? "network_wifi" : "signal_wifi_off"
            }
        }
    }

    fullRepresentation: QuickSettingsView {
        backend: plasmaBackend
        tiles: Plasmoid.configuration.tiles
        Layout.preferredWidth: implicitWidth
        Layout.preferredHeight: implicitHeight
        Layout.minimumWidth: implicitWidth
        Layout.minimumHeight: implicitHeight
        onCloseRequested: root.expanded = false
    }
}
