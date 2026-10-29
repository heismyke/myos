import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCMUtils

// Chooses which tiles Quick Settings shows. Figma has no tile editor, so this
// uses the standard Plasma configuration dialog.
KCMUtils.SimpleKCM {
    property var cfg_tiles: []
    property alias cfg_lightColorScheme: lightScheme.text
    property alias cfg_darkColorScheme: darkScheme.text

    readonly property var allTiles: [
        ["network", qsTr("Internet")], ["bluetooth", qsTr("Bluetooth")],
        ["batterySaver", qsTr("Battery Saver")], ["darkMode", qsTr("Dark Mode")],
        ["temperature", qsTr("Temperature")], ["micAccess", qsTr("Mic Access")],
        ["accessibility", qsTr("Accessibility")], ["screenCapture", qsTr("Screen Capture")],
        ["keyboard", qsTr("Keyboard")]
    ]

    Kirigami.FormLayout {
        Repeater {
            model: allTiles
            QQC2.CheckBox {
                required property var modelData
                required property int index
                Kirigami.FormData.label: index === 0 ? qsTr("Tiles:") : ""
                text: modelData[1]
                checked: cfg_tiles.includes(modelData[0])
                onToggled: {
                    // Keep the canonical order so the grid packs predictably.
                    const on = new Set(cfg_tiles);
                    checked ? on.add(modelData[0]) : on.delete(modelData[0]);
                    cfg_tiles = allTiles.map(t => t[0]).filter(id => on.has(id));
                }
            }
        }

        QQC2.TextField {
            id: lightScheme
            Kirigami.FormData.label: qsTr("Light colour scheme:")
        }
        QQC2.TextField {
            id: darkScheme
            Kirigami.FormData.label: qsTr("Dark colour scheme:")
        }
    }
}
