import QtQuick
import QtQuick.Effects

// The dark rounded card that panels sit on, with the Figma drop shadow
// (0 1 4 rgba(0,0,0,0.16)).
Item {
    id: root

    default property alias content: inner.data
    property int padding: Tokens.spacingLg

    implicitWidth: inner.childrenRect.width + 2 * padding
    implicitHeight: inner.childrenRect.height + 2 * padding

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Tokens.radiusPanel
        color: Tokens.surface
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Tokens.shadow
            shadowVerticalOffset: Tokens.shadowOffsetY
            blurMax: 2 * Tokens.shadowBlur
            shadowBlur: 0.5
        }
    }

    Item {
        id: inner
        x: root.padding
        y: root.padding
        width: root.width - 2 * root.padding
        height: root.height - 2 * root.padding
    }
}
