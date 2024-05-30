package three.js.test.unit.src.geometries;

import three.js.src.geometries.ConeGeometry;
import three.js.src.geometries.CylinderGeometry;
import three.js.utils.qunitUtils.runStdGeometryTests;

class ConeGeometryTests {

    static function main() {
        var module = new QUnitModule("Geometries");
        module.module("ConeGeometry", (hooks) -> {
            var geometries:Array<ConeGeometry> = [];
            hooks.beforeEach(() -> {
                geometries = [new ConeGeometry()];
            });

            // INHERITANCE
            QUnit.test("Extending", (assert) -> {
                var object = new ConeGeometry();
                assert.strictEqual(
                    Std.instance(object, CylinderGeometry), true,
                    'ConeGeometry extends from CylinderGeometry'
                );
            });

            // INSTANCING
            QUnit.test("Instancing", (assert) -> {
                var object = new ConeGeometry();
                assert.ok(object, 'Can instantiate a ConeGeometry.');
            });

            // PROPERTIES
            QUnit.test("type", (assert) -> {
                var object = new ConeGeometry();
                assert.ok(
                    object.type == 'ConeGeometry',
                    'ConeGeometry.type should be ConeGeometry'
                );
            });

            QUnit.todo("parameters", (assert) -> {
                assert.ok(false, 'everything\'s gonna be alright');
            });

            // STATIC
            QUnit.todo("fromJSON", (assert) -> {
                assert.ok(false, 'everything\'s gonna be alright');
            });

            // OTHERS
            QUnit.test("Standard geometry tests", (assert) -> {
                runStdGeometryTests(assert, geometries);
            });
        });
    }
}