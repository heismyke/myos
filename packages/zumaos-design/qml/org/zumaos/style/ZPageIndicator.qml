import QtQuick

// Page dots (Figma 1:16812): the current page is a 24x8 pill, the rest 8px dots.
Row {
    id: root

    property int count: 1
    property int currentIndex: 0

    spacing: Tokens.spacingXs
    topPadding: Tokens.spacingXs
    bottomPadding: Tokens.spacingXs

    Repeater {
        model: root.count
        Rectangle {
            required property int index
            width: index === root.currentIndex ? Tokens.pageDotActiveWidth : Tokens.pageDot
            height: Tokens.pageDot
            radius: Tokens.radiusFull
            color: index === root.currentIndex ? Tokens.control : Tokens.controlMuted
            Behavior on width { NumberAnimation { duration: Tokens.durationShort } }
        }
    }
}
