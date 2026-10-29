import QtQuick
import QtQuick.Window

// Renders the Quick Settings view against DesignBackend at the Figma frame's
// size. Run with dev/run-preview.sh; "--tiles=a,b,..." overrides the tile set.
Window {
    width: view.implicitWidth
    height: view.implicitHeight
    visible: true
    color: "white"
    title: "ZumaOS Quick Settings preview"

    DesignBackend { id: designBackend }

    Loader {
        id: view

        Component.onCompleted: {
            const props = { backend: designBackend };
            const tiles = Qt.application.arguments.find(a => a.startsWith("--tiles="));
            if (tiles)
                props.tiles = tiles.slice(8).split(",");
            setSource(Qt.resolvedUrl("../../packages/zumaos-quicksettings/package/contents/ui/QuickSettingsView.qml"), props);
        }
    }

    // "--screenshot=file.png" saves the render and quits.
    Timer {
        readonly property string path: {
            const arg = Qt.application.arguments.find(a => a.startsWith("--screenshot="));
            return arg ? arg.slice(13) : "";
        }
        running: path.length > 0
        interval: 1500
        onTriggered: view.grabToImage(result => {
            result.saveToFile(path);
            Qt.quit();
        })
    }
}
