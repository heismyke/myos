pragma Singleton
import QtQuick

// ZumaOS design tokens. Values come from the Figma file (see tokens.json in
// the zumaos-design source, which lists the source nodes); change them there
// first and mirror them here.
QtObject {
    // Colour
    readonly property color surface: "#2d2d2d"
    readonly property color control: "#9a9a9a"
    readonly property color controlMuted: "#7b7b7b"
    readonly property color controlActive: "#ffffff"
    readonly property color content: "#ffffff"
    readonly property color contentActive: "#2d2d2d"
    readonly property color shadow: Qt.rgba(0, 0, 0, 0.16)
    readonly property int shadowOffsetY: 1
    readonly property int shadowBlur: 4

    // Interaction overlays. Figma has no hover/pressed frames; these are the
    // Material state-layer opacities, matching the Material Symbols iconography.
    readonly property real hoverOpacity: 0.08
    readonly property real pressedOpacity: 0.12
    readonly property color focusRing: "#ffffff"

    // Shape
    readonly property int radiusPanel: 40
    readonly property int radiusControl: 32
    readonly property int radiusFull: 60
    readonly property int radiusSegmentInner: 4 // where two shelf pills join
    readonly property int radiusShelf: 28 // shelf top corners

    // Spacing
    readonly property int spacingXs: 8
    readonly property int spacingSm: 10
    readonly property int spacingMd: 12
    readonly property int spacingLg: 16
    readonly property int spacingXl: 24

    // Size
    readonly property int iconSize: 24
    readonly property int iconButtonSize: 40
    readonly property int tileHeight: 88
    readonly property int panelContentWidth: 448
    readonly property int sliderTrack: 4
    readonly property int pageDot: 8
    readonly property int pageDotActiveWidth: 24
    readonly property int shelfHeight: 56
    readonly property int segmentGap: 4

    // Type
    readonly property string fontFamily: "Manrope"
    readonly property int fontSize: 14
    readonly property int weightTitle: Font.Medium
    readonly property int weightBody: Font.Normal
    // The shelf's date and time use a different face from the panels.
    readonly property string shelfFontFamily: "Readex Pro"

    // Bundled Material Symbols glyphs (icons/), from the Figma file.
    readonly property var icons: ["accessibility_new", "art_track", "auto_awesome", "battery_charging_full", "battery_full", "battery_saver", "bluetooth_connected", "brightness_6", "browser_updated", "center_focus_weak", "chevron_right", "contrast", "edit", "keyboard", "keyboard_voice", "local_mall", "logout", "mode_off_on", "network_wifi", "settings", "signal_wifi_off", "thermostat", "volume_up"]

    // Motion. Figma has no animation specs for these components.
    readonly property int durationShort: 120
}
