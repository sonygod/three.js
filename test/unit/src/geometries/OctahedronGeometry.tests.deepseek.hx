package three.js.test.unit.src.geometries;

import three.js.src.geometries.OctahedronGeometry;
import three.js.src.geometries.PolyhedronGeometry;
import three.js.utils.qunit.QUnit;
import three.js.utils.qunit.runStdGeometryTests;

class OctahedronGeometryTests {

    public static function main():Void {

        QUnit.module('Geometries', () -> {

            QUnit.module('OctahedronGeometry', (hooks) -> {

                var geometries:Array<OctahedronGeometry>;
                hooks.beforeEach(() -> {

                    var parameters = {
                        radius: 10,
                        detail: null
                    };

                    geometries = [
                        new OctahedronGeometry(),
                        new OctahedronGeometry(parameters.radius),
                        new OctahedronGeometry(parameters.radius, parameters.detail)
                    ];

                });

                // INHERITANCE
                QUnit.test('Extending', (assert) -> {

                    var object = new OctahedronGeometry();
                    assert.strictEqual(
                        Std.is(object, PolyhedronGeometry), true,
                        'OctahedronGeometry extends from PolyhedronGeometry'
                    );

                });

                // INSTANCING
                QUnit.test('Instancing', (assert) -> {

                    var object = new OctahedronGeometry();
                    assert.ok(object, 'Can instantiate an OctahedronGeometry.');

                });

                // PROPERTIES
                QUnit.test('type', (assert) -> {

                    var object = new OctahedronGeometry();
                    assert.ok(
                        object.type == 'OctahedronGeometry',
                        'OctahedronGeometry.type should be OctahedronGeometry'
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