package three.js.test.unit.src.geometries;

import three.js.src.geometries.PolyhedronGeometry;
import three.js.src.core.BufferGeometry;
import three.js.utils.qunit_utils.runStdGeometryTests;

class PolyhedronGeometryTests {

    static function main() {

        unittest.suite('Geometries', () -> {

            unittest.suite('PolyhedronGeometry', (hooks) -> {

                var geometries:Array<PolyhedronGeometry> = [];
                hooks.beforeEach(() -> {

                    var vertices:Array<Float> = [
                        1, 1, 1, -1, -1, 1, -1, 1, -1, 1, -1, -1
                    ];

                    var indices:Array<Int> = [
                        2, 1, 0, 0, 3, 2, 1, 3, 0, 2, 3, 1
                    ];

                    geometries = [
                        new PolyhedronGeometry(vertices, indices),
                    ];

                });

                // INHERITANCE
                unittest.test('Extending', (assert) -> {

                    var object = new PolyhedronGeometry();
                    assert.strictEqual(
                        Std.is(object, BufferGeometry), true,
                        'PolyhedronGeometry extends from BufferGeometry'
                    );

                });

                // INSTANCING
                unittest.test('Instancing', (assert) -> {

                    var object = new PolyhedronGeometry();
                    assert.ok(object, 'Can instantiate a PolyhedronGeometry.');

                });

                // PROPERTIES
                unittest.test('type', (assert) -> {

                    var object = new PolyhedronGeometry();
                    assert.ok(
                        object.type == 'PolyhedronGeometry',
                        'PolyhedronGeometry.type should be PolyhedronGeometry'
                    );

                });

                unittest.todo('parameters', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                // STATIC
                unittest.todo('fromJSON', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                // OTHERS
                unittest.test('Standard geometry tests', (assert) -> {

                    runStdGeometryTests(assert, geometries);

                });

            });

        });

    }

}