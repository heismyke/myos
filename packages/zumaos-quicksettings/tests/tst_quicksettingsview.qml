import QtQuick
import QtTest
import "../../../dev/preview"
import "../package/contents/ui"

// Interaction tests for QuickSettingsView against the design-state backend.
// Run: dev/run-tests.sh
Item {
    id: root
    width: 496
    height: 800

    DesignBackend { id: backend }

    QuickSettingsView {
        id: view
        backend: backend
    }

    SignalSpy { id: closeSpy; target: view; signalName: "closeRequested" }

    function findTile(item, title) {
        if (item.title === title && item.hasDetails !== undefined)
            return item;
        for (const child of item.children) {
            const found = findTile(child, title);
            if (found)
                return found;
        }
        return null;
    }

    TestCase {
        name: "QuickSettingsView"
        when: windowShown

        function init() {
            view.tiles = ["network", "bluetooth", "batterySaver", "darkMode",
                          "accessibility", "screenCapture", "keyboard"];
            backend.batterySaver = false;
            backend.wifiEnabled = true;
            closeSpy.clear();
        }

        function test_size_matches_figma_frames() {
            // Master component 1:6291 (three tile rows).
            tryCompare(view, "implicitWidth", 496);
            tryCompare(view, "implicitHeight", 680);
            // Instance 1:16730 adds the Temperature / Mic Access row.
            view.tiles = view.tiles.slice(0, 4).concat(["temperature", "micAccess"], view.tiles.slice(4));
            tryCompare(view, "implicitHeight", 776);
        }

        function test_default_tiles_pack_into_three_rows() {
            compare(view.pages.length, 1);
            compare(JSON.stringify(view.pages[0]), JSON.stringify(
                [["network", "bluetooth"], ["batterySaver", "darkMode"],
                 ["accessibility", "screenCapture", "keyboard"]]));
        }

        function test_optional_tiles_add_a_row() {
            view.tiles = ["network", "bluetooth", "batterySaver", "darkMode",
                          "temperature", "micAccess", "accessibility", "screenCapture", "keyboard"];
            compare(view.pages[0].length, 4);
        }

        function test_unknown_tile_ids_are_ignored() {
            view.tiles = ["network", "doesNotExist"];
            compare(JSON.stringify(view.pages), JSON.stringify([[["network"]]]));
        }

        function test_toggle_tile_updates_backend_and_style() {
            const tile = findTile(view, "Battery Saver");
            verify(tile);
            verify(!tile.active);
            mouseClick(tile);
            verify(backend.batterySaver);
            tryCompare(tile, "active", true);
            compare(tile.subtitle, "On");
        }

        function test_keyboard_activation() {
            const tile = findTile(view, "Internet");
            tile.forceActiveFocus(Qt.TabFocusReason);
            keyClick(Qt.Key_Space);
            verify(!backend.wifiEnabled);
        }

        function test_details_chevron_opens_settings_and_closes() {
            const tile = findTile(view, "Internet");
            const before = backend.wifiEnabled;
            mouseClick(tile, tile.width - 24, tile.height / 2);
            compare(backend.wifiEnabled, before, "chevron must not toggle");
            compare(closeSpy.count, 1);
        }
    }
}
