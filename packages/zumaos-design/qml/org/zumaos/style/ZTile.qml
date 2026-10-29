import QtQuick
import QtQuick.Templates as T

// Quick Settings tile (Figma 1:16751 and siblings). `active` gives the white
// tile; `muted` the darker one used by Mic Access. A tile with `hasDetails`
// shows a chevron that emits detailsClicked() instead of clicked().
// `compact` stacks icon over a centred label, as Screen Capture and Keyboard do.
T.AbstractButton {
    id: tile

    property string iconName
    property string title
    property string subtitle
    property bool active: false
    property bool muted: false
    property bool hasDetails: false
    property bool compact: false

    signal detailsClicked()

    readonly property color foreground: active ? Tokens.contentActive : Tokens.content

    implicitHeight: Tokens.tileHeight
    implicitWidth: 2 * Tokens.spacingMd + Tokens.iconSize
    padding: Tokens.spacingMd
    leftPadding: compact ? Tokens.spacingLg : Tokens.spacingMd
    rightPadding: leftPadding
    focusPolicy: Qt.StrongFocus

    Accessible.name: subtitle ? title + ", " + subtitle : title

    background: Rectangle {
        radius: Tokens.radiusControl
        color: tile.active ? Tokens.controlActive : tile.muted ? Tokens.controlMuted : Tokens.control
        Behavior on color { ColorAnimation { duration: Tokens.durationShort } }

        ZStateLayer {
            control: tile
            tint: tile.foreground
        }
    }

    contentItem: Item {
        // Row layout: icon, text, optional chevron.
        Row {
            visible: !tile.compact
            anchors.fill: parent
            spacing: Tokens.spacingMd

            ZIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: tile.iconName
                color: tile.foreground
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - Tokens.iconSize - parent.spacing
                    - (tile.hasDetails ? details.width + parent.spacing : 0)

                Text {
                    width: parent.width
                    text: tile.title
                    color: tile.foreground
                    elide: Text.ElideRight
                    font.family: Tokens.fontFamily
                    font.pixelSize: Tokens.fontSize
                    font.weight: Tokens.weightTitle
                }
                Text {
                    width: parent.width
                    visible: text.length > 0
                    text: tile.subtitle
                    color: tile.foreground
                    elide: Text.ElideRight
                    font.family: Tokens.fontFamily
                    font.pixelSize: Tokens.fontSize
                    font.weight: Tokens.weightBody
                }
            }

            T.AbstractButton {
                id: details
                visible: tile.hasDetails
                anchors.verticalCenter: parent.verticalCenter
                width: Tokens.iconSize
                height: Tokens.iconSize
                focusPolicy: Qt.StrongFocus
                Accessible.name: tile.title + " details"
                onClicked: tile.detailsClicked()

                contentItem: ZIcon {
                    name: "chevron_right"
                    color: tile.foreground
                }
                background: ZStateLayer {
                    control: details
                    radius: width / 2
                    tint: tile.foreground
                    anchors.margins: -4
                }
            }
        }

        // Compact layout: icon over a centred, wrapping label.
        Column {
            visible: tile.compact
            anchors.centerIn: parent
            width: parent.width
            spacing: Tokens.spacingXs

            ZIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: tile.iconName
                color: tile.foreground
            }
            Text {
                width: parent.width
                text: tile.title
                color: tile.foreground
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                font.family: Tokens.fontFamily
                font.pixelSize: Tokens.fontSize
                font.weight: Tokens.weightTitle
            }
        }
    }
}
