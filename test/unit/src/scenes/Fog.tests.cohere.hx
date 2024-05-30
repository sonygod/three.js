import js.QUnit;

import Fog from "../../../../src/scenes/Fog.hx";

class _Main {
    static function main() {
        QUnit.module("Scenes", {
            setup: function() {},
            teardown: function() {}
        });

        QUnit.module("Fog", {
            setup: function() {},
            teardown: function() {}
        });

        // INSTANCING
        QUnit.test("Instancing", function(assert) {
            // Fog(color:Int, near:Float, far:Float)

            // no params
            var object = new Fog();
            assert.ok(object, "Can instantiate a Fog.");

            // color
            var object_color = new Fog(0xffffff);
            assert.ok(object_color, "Can instantiate a Fog with color.");

            // color, near, far
            var object_all = new Fog(0xffffff, 0.015, 100);
            assert.ok(object_all, "Can instantiate a Fog with color, near, far.");
        });

        // PROPERTIES
        QUnit.todo("name", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("color", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("near", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("far", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        // PUBLIC
        QUnit.test("isFog", function(assert) {
            var object = new Fog();
            assert.ok(object.isFog, "Fog.isFog should be true");
        });

        QUnit.todo("clone", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("toJSON", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });
    }
}