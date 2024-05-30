import js.QUnit;
import PlaneHelper from "../../../../src/helpers/PlaneHelper.hx";
import Line from "../../../../src/objects/Line.hx";

class _Main {
    static function main() {
        QUnit.module("Helpers", {
            setup: function() {},
            teardown: function() {}
        });

        QUnit.module("PlaneHelper", {
            setup: function() {},
            teardown: function() {}
        });

        // INHERITANCE
        QUnit.test("Extending", function(assert) {
            var object = new PlaneHelper();
            assert.strictEqual(object instanceof Line, true, "PlaneHelper extends from Line");
        });

        // INSTANCING
        QUnit.test("Instancing", function(assert) {
            var object = new PlaneHelper();
            assert.ok(object, "Can instantiate a PlaneHelper.");
        });

        // PROPERTIES
        QUnit.test("type", function(assert) {
            var object = new PlaneHelper();
            assert.ok(object.type == "PlaneHelper", "PlaneHelper.type should be PlaneHelper");
        });

        QUnit.todo("plane", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("size", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        // PUBLIC
        QUnit.todo("updateMatrixWorld", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.test("dispose", function(assert) {
            assert.expect(0);
            var object = new PlaneHelper();
            object.dispose();
        });
    }
}