import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.zumaos.style

// The art_track button at the shelf's right end (Figma 1:16902). The design
// gives it no action; it opens KWin's Overview, as Meta+W does.
PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation
    toolTipMainText: qsTr("Overview")

    P5Support.DataSource {
        id: run
        engine: "executable"
        onNewData: source => disconnectSource(source)
    }

    fullRepresentation: Item {
        Layout.minimumWidth: Tokens.iconButtonSize
        Layout.preferredWidth: Tokens.iconButtonSize
        Layout.maximumWidth: Tokens.iconButtonSize

        ZIconButton {
            anchors.centerIn: parent
            iconName: "art_track"
            text: qsTr("Overview")
            onClicked: run.connectSource("dbus-send --session --type=method_call --dest=org.kde.kglobalaccel "
                + "/component/kwin org.kde.kglobalaccel.Component.invokeShortcut string:Overview")
        }
    }
}
