import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.workspace.calendar as PlasmaCalendar
import org.zumaos.style

// Shelf date and time (Figma 1:16881): "Dec. 6, Tuesday" and "12:46" in two
// joined pills. Either opens a month calendar.
PlasmoidItem {
    id: root

    property date now: new Date()

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: compactRepresentation
    toolTipMainText: Qt.locale().toString(now, "dddd")
    toolTipSubText: Qt.locale().toString(now, Locale.LongFormat)

    // "Dec. 6, Tuesday": abbreviated month with a full stop, unless the
    // abbreviation is the whole name ("May").
    function dateText(d) {
        const locale = Qt.locale();
        const abbr = locale.monthName(d.getMonth(), Locale.ShortFormat);
        const full = locale.monthName(d.getMonth(), Locale.LongFormat);
        const month = abbr === full ? abbr : abbr + ".";
        return qsTr("%1 %2, %3").arg(month).arg(d.getDate())
            .arg(locale.dayName(d.getDay(), Locale.LongFormat));
    }

    // "12:46": the locale's short time, without seconds (some locales' short
    // format has them).
    function timeText(d) {
        const format = Qt.locale().timeFormat(Locale.ShortFormat).replace(/[:.]ss?/, "");
        return Qt.locale().toString(d, format);
    }

    Timer {
        // Tick on the minute.
        interval: 60000 - (root.now.getSeconds() * 1000 + root.now.getMilliseconds())
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    compactRepresentation: Row {
        spacing: Tokens.segmentGap

        Layout.minimumWidth: implicitWidth
        Layout.preferredWidth: implicitWidth
        Layout.maximumWidth: implicitWidth

        Repeater {
            model: [
                { edge: Qt.AlignLeft, text: root.dateText(root.now) },
                { edge: Qt.AlignRight, text: root.timeText(root.now) },
            ]
            ZPillSegment {
                required property var modelData
                anchors.verticalCenter: parent.verticalCenter
                edge: modelData.edge
                text: modelData.text
                onClicked: root.expanded = !root.expanded

                Text {
                    text: modelData.text
                    color: Tokens.content
                    font.family: Tokens.shelfFontFamily
                    font.pixelSize: Tokens.fontSize
                    font.weight: Tokens.weightBody
                }
            }
        }
    }

    fullRepresentation: PlasmaCalendar.MonthView {
        Layout.preferredWidth: 360
        Layout.preferredHeight: 340
        Layout.minimumWidth: 300
        Layout.minimumHeight: 300
        today: root.now
        showWeekNumbers: false
    }
}
