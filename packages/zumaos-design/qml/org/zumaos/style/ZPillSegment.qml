import QtQuick
import QtQuick.Templates as T

// One half of a split pill on the shelf (Figma 1:16881, 1:16886): two pills
// 4px apart, fully rounded on the outside and 4px on the side where they
// meet. Children are laid out in a row, 12px apart.
T.AbstractButton {
    id: button

    // Which end of the pair this is: Qt.AlignLeft or Qt.AlignRight.
    property int edge: Qt.AlignLeft
    default property alias content: row.data

    readonly property real outerRadius: height / 2
    readonly property real leftRadius: edge === Qt.AlignLeft ? outerRadius : Tokens.radiusSegmentInner
    readonly property real rightRadius: edge === Qt.AlignRight ? outerRadius : Tokens.radiusSegmentInner

    implicitWidth: implicitContentWidth + leftPadding + rightPadding
    implicitHeight: Tokens.iconButtonSize
    leftPadding: Tokens.spacingMd
    rightPadding: Tokens.spacingMd
    focusPolicy: Qt.StrongFocus
    Accessible.name: text

    background: Rectangle {
        color: Tokens.control
        topLeftRadius: button.leftRadius
        bottomLeftRadius: button.leftRadius
        topRightRadius: button.rightRadius
        bottomRightRadius: button.rightRadius

        ZStateLayer {
            control: button
            topLeftRadius: button.leftRadius
            bottomLeftRadius: button.leftRadius
            topRightRadius: button.rightRadius
            bottomRightRadius: button.rightRadius
        }
    }

    contentItem: Item {
        implicitWidth: row.implicitWidth
        implicitHeight: row.implicitHeight
        Row {
            id: row
            anchors.centerIn: parent
            spacing: Tokens.spacingMd
        }
    }
}
