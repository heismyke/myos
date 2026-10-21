import QtQuick

// Login splash, macOS-style: the ZumaOS wordmark on black with a slim
// progress bar. ksplash advances `stage` from 1 to 6 as Plasma starts.
Rectangle {
    id: root
    property int stage

    color: "#000000"

    Image {
        id: wordmark
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -height
        source: "file:///usr/share/zumaos-logos/zumaos-wordmark.png"
        height: 56
        fillMode: Image.PreserveAspectFit
        smooth: true
        opacity: 0
        Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
        Component.onCompleted: opacity = 1
    }

    Rectangle {
        anchors.top: wordmark.bottom
        anchors.topMargin: 56
        anchors.horizontalCenter: parent.horizontalCenter
        width: 180
        height: 4
        radius: height / 2
        color: Qt.rgba(1, 1, 1, 0.18)

        Rectangle {
            height: parent.height
            radius: parent.radius
            width: parent.width * Math.min(root.stage, 6) / 6
            color: "#FFFFFF"
            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        }
    }
}
