package;

import js.QUnit;

class TestExtras {
    public static function test() : Void {
        QUnit.module("Extras", {
            beforeEach: function() {
                // ...
            },
            afterEach: function() {
                // ...
            }
        });

        QUnit.module("ImageUtils", {
            beforeEach: function() {
                // ...
            },
            afterEach: function() {
                // ...
            }
        });

        // STATIC
        QUnit.todo("getDataURL", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("sRGBToLinear", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });
    }
}