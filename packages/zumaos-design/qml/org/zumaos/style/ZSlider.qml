import QtQuick
import QtQuick.Templates as T

// Volume / brightness slider (Figma 1:16818, 1:16828): a pill that grows with
// the value and carries the icon at its end, over a thin muted track.
T.Slider {
    id: slider

    property string iconName

    from: 0
    to: 1
    stepSize: 0.01
    implicitWidth: 200
    implicitHeight: Tokens.iconSize + 2 * Tokens.spacingMd
    focusPolicy: Qt.StrongFocus
    // Keep at least the icon's pill visible at 0.
    leftPadding: 0
    rightPadding: 0

    readonly property real fillWidth: height + slider.visualPosition * (width - height)

    background: Item {
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: Tokens.sliderTrack
            radius: height / 2
            color: Tokens.controlMuted
        }

        Rectangle {
            id: fill
            width: slider.fillWidth
            height: parent.height
            radius: Tokens.radiusControl
            color: Tokens.control

            ZIcon {
                anchors.right: parent.right
                anchors.rightMargin: Tokens.spacingMd
                anchors.verticalCenter: parent.verticalCenter
                name: slider.iconName
            }

            ZStateLayer {
                control: slider
                radius: parent.radius
            }
        }
    }

    // The pill's end is the handle; nothing extra is drawn.
    handle: Item {
        x: slider.fillWidth - width
        width: slider.height
        height: slider.height
    }
}
