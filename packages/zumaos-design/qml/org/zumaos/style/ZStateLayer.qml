import QtQuick

// Hover / pressed overlay and keyboard focus ring for a rounded control.
// Put it inside the control's background and point `control` at the button.
Item {
    id: root

    property Item control
    property real radius: Tokens.radiusControl
    // Per-corner radii, for shapes like ZPillSegment.
    property real topLeftRadius: radius
    property real topRightRadius: radius
    property real bottomLeftRadius: radius
    property real bottomRightRadius: radius
    property color tint: Tokens.content

    anchors.fill: parent

    Rectangle {
        anchors.fill: parent
        topLeftRadius: root.topLeftRadius
        topRightRadius: root.topRightRadius
        bottomLeftRadius: root.bottomLeftRadius
        bottomRightRadius: root.bottomRightRadius
        color: root.tint
        opacity: !root.control || !root.control.enabled ? 0
            : root.control.pressed ? Tokens.pressedOpacity
            : root.control.hovered ? Tokens.hoverOpacity : 0
        Behavior on opacity { NumberAnimation { duration: Tokens.durationShort } }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -3
        topLeftRadius: root.topLeftRadius + 3
        topRightRadius: root.topRightRadius + 3
        bottomLeftRadius: root.bottomLeftRadius + 3
        bottomRightRadius: root.bottomRightRadius + 3
        color: "transparent"
        border.width: 2
        border.color: Tokens.focusRing
        visible: root.control !== null && root.control.visualFocus
    }
}
