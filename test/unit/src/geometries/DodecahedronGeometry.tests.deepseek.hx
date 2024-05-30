package;

import js.Lib;
import three.js.test.unit.src.geometries.DodecahedronGeometry;
import three.js.test.unit.src.geometries.PolyhedronGeometry;
import three.js.test.unit.utils.qunit_utils.runStdGeometryTests;

class DodecahedronGeometryTests {

    static function main() {
        QUnit.module('Geometries', () -> {
            QUnit.module('DodecahedronGeometry', (hooks) -> {
                var geometries:Array<DodecahedronGeometry> = [];
                hooks.beforeEach(() -> {
                    var parameters = {
                        radius: 10,
                        detail: null
                    };
                    geometries = [
                        new DodecahedronGeometry(),
                        new DodecahedronGeometry(parameters.radius),
                        new DodecahedronGeometry(parameters.radius, parameters.detail)
                    ];
                });

                // INHERITANCE
                QUnit.test('Extending', (assert) -> {
                    var object = new DodecahedronGeometry();
                    assert.strictEqual(
                        Std.instance(object, PolyhedronGeometry), true,
                        'DodecahedronGeometry extends from PolyhedronGeometry'
                    );
                });

                // INSTANCING
                QUnit.test('Instancing', (assert) -> {
                    var object = new DodecahedronGeometry();
                    assert.ok(object, 'Can instantiate a DodecahedronGeometry.');
                });

                // PROPERTIES
                QUnit.test('type', (assert) -> {
                    var object = new DodecahedronGeometry();
                    assert.ok(
                        object.type == 'DodecahedronGeometry',
                        'DodecahedronGeometry.type should be DodecahedronGeometry'
                    );
                });

                QUnit.todo('parameters', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // STATIC
                QUnit.todo('fromJSON', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // OTHERS
                QUnit.test('Standard geometry tests', (assert) -> {
                    runStdGeometryTests(assert, geometries);
                });
            });
        });
    }
}