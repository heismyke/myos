import QtQuick
import QtQuick.Templates as T

// Round 40px icon button (Figma 1:16734, 1:16836). Filled with the control
// colour by default; `outlined` gives the 1px muted ring used in the footer.
T.AbstractButton {
    id: button

    property string iconName
    property bool outlined: false
    property real iconRotation: 0
    property int size: Tokens.iconButtonSize

    implicitWidth: size
    implicitHeight: size
    focusPolicy: Qt.StrongFocus
    Accessible.name: text

    background: Rectangle {
        radius: height / 2
        color: button.outlined ? "transparent" : Tokens.control
        border.width: button.outlined ? 1 : 0
        border.color: Tokens.controlMuted

        ZStateLayer {
            control: button
            radius: parent.radius
        }
    }

    contentItem: Item {
        ZIcon {
            anchors.centerIn: parent
            name: button.iconName
            rotation: button.iconRotation
        }
    }
}
