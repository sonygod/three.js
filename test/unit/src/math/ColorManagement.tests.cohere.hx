import js.QUnit;

import js.Math.ColorManagement;

class ColorManagementTest {
    static function enabled() {
        var enabled = ColorManagement.enabled;
        var expected = true;
        QUnit.strictEqual(enabled, expected, "ColorManagement.enabled 默认值为 true");
    }

    static function main() {
        QUnit.module("Maths", setup => {
            setup.module("ColorManagement", () -> {
                QUnit.test("enabled", ColorManagementTest.enabled);
            });
        });
    }
}

ColorManagementTest.main();