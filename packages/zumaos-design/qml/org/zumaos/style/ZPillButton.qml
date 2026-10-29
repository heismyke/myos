import QtQuick
import QtQuick.Templates as T

// Text pill button, e.g. "Clear all" (Figma 1:16747) and "History".
T.AbstractButton {
    id: button

    implicitWidth: implicitContentWidth + leftPadding + rightPadding
    implicitHeight: Tokens.iconButtonSize
    leftPadding: Tokens.spacingMd
    rightPadding: Tokens.spacingMd
    focusPolicy: Qt.StrongFocus

    background: Rectangle {
        radius: Tokens.radiusControl
        color: Tokens.control
        opacity: button.enabled ? 1 : 0.5

        ZStateLayer {
            control: button
            radius: parent.radius
        }
    }

    contentItem: Text {
        text: button.text
        color: Tokens.content
        verticalAlignment: Text.AlignVCenter
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.fontSize
        font.weight: Tokens.weightBody
    }
}
