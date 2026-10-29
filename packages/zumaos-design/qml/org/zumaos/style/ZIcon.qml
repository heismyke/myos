import QtQuick
import Qt5Compat.GraphicalEffects
import org.kde.kirigami as Kirigami

// A Material Symbols glyph from this module's icons/ folder, tinted to `color`
// (the SVG's alpha is kept, its colour replaced). Names not in the set, such
// as an app's icon on a notification, come from the icon theme untinted.
Item {
    id: root

    property string name
    property color color: Tokens.content

    readonly property bool bundled: Tokens.icons.includes(name)

    implicitWidth: Tokens.iconSize
    implicitHeight: Tokens.iconSize

    Image {
        id: glyph
        anchors.fill: parent
        source: root.bundled ? Qt.resolvedUrl("icons/" + root.name + ".svg") : ""
        sourceSize: Qt.size(width * Screen.devicePixelRatio, height * Screen.devicePixelRatio)
        visible: false
    }

    ColorOverlay {
        anchors.fill: parent
        visible: root.bundled
        source: glyph
        color: root.color
    }

    Kirigami.Icon {
        anchors.fill: parent
        visible: !root.bundled && root.name.length > 0
        source: root.bundled ? "" : root.name
        roundToIconSize: false
    }
}
