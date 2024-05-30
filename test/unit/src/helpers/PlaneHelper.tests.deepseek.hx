package;

import three.js.test.unit.src.helpers.PlaneHelper;
import three.js.test.unit.src.objects.Line;

class PlaneHelperTest {

    static function main() {
        var module = new QUnit.Module("Helpers");
        module.module("PlaneHelper", () -> {

            // INHERITANCE
            QUnit.test("Extending", (assert) -> {
                var object = new PlaneHelper();
                assert.strictEqual(
                    Std.instance(object, Line), true,
                    'PlaneHelper extends from Line'
                );
            });

            // INSTANCING
            QUnit.test("Instancing", (assert) -> {
                var object = new PlaneHelper();
                assert.ok(object, 'Can instantiate a PlaneHelper.');
            });

            // PROPERTIES
            QUnit.test("type", (assert) -> {
                var object = new PlaneHelper();
                assert.ok(
                    object.type == 'PlaneHelper',
                    'PlaneHelper.type should be PlaneHelper'
                );
            });

            QUnit.todo("plane", (assert) -> {
                assert.ok(false, 'everything\'s gonna be alright');
            });

            QUnit.todo("size", (assert) -> {
                assert.ok(false, 'everything\'s gonna be alright');
            });

            // PUBLIC
            QUnit.todo("updateMatrixWorld", (assert) -> {
                assert.ok(false, 'everything\'s gonna be alright');
            });

            QUnit.test("dispose", (assert) -> {
                assert.expect(0);
                var object = new PlaneHelper();
                object.dispose();
            });
        });
    }
}