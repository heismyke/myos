import QtQuick

// Login splash: the ZumaOS logo over the wallpaper with a slim glass
// progress pill. ksplash advances `stage` from 1 to 6 as Plasma starts.
Image {
    id: root
    property int stage

    source: "file:///usr/share/wallpapers/ZumaOS/contents/images/3840x2160.png"
    fillMode: Image.PreserveAspectCrop

    Image {
        id: logo
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -height / 4
        source: "file:///usr/share/zumaos-logos/zumaos-logo.svg"
        sourceSize.width: 128
        sourceSize.height: 128
        opacity: 0
        Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
        Component.onCompleted: opacity = 1
    }

    Rectangle {
        id: track
        anchors.top: logo.bottom
        anchors.topMargin: 48
        anchors.horizontalCenter: parent.horizontalCenter
        width: 200
        height: 6
        radius: height / 2
        color: Qt.rgba(1, 1, 1, 0.12)
        border.color: Qt.rgba(1, 1, 1, 0.25)
        border.width: 1

        Rectangle {
            height: parent.height
            radius: parent.radius
            width: parent.width * Math.min(root.stage, 6) / 6
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "#FFC56B" }
                GradientStop { position: 1; color: "#F28C38" }
            }
            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        }
    }
}
