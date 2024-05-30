package;

import js.QUnit;
import js.d3.geometries.TorusKnotGeometry;
import js.d3.core.BufferGeometry;
import js.d3.utils.qunit.runStdGeometryTests;

class _TorusKnotGeometryTest {
    static function test() {
        var geometries:Array<TorusKnotGeometry>;

        QUnit.module('Geometries', function () {
            QUnit.module('TorusKnotGeometry', function (hooks) {
                hooks.beforeEach(function () {
                    var parameters = {
                        radius: 10,
                        tube: 20,
                        tubularSegments: 30,
                        radialSegments: 10,
                        p: 3,
                        q: 2
                    };

                    geometries = [
                        new TorusKnotGeometry(),
                        new TorusKnotGeometry(parameters.radius),
                        new TorusKnotGeometry(parameters.radius, parameters.tube),
                        new TorusKnotGeometry(parameters.radius, parameters.tube, parameters.tubularSegments),
                        new TorusKnotGeometry(parameters.radius, parameters.tube, parameters.tubularSegments, parameters.radialSegments),
                        new TorusKnotGeometry(parameters.radius, parameters.tube, parameters.tubularSegments, parameters.radialSegments, parameters.p, parameters.q)
                    ];
                });

                // INHERITANCE
                QUnit.test('Extending', function (assert) {
                    var object = new TorusKnotGeometry();
                    assert.strictEqual(object instanceof BufferGeometry, true, 'TorusKnotGeometry extends from BufferGeometry');
                });

                // INSTANCING
                QUnit.test('Instancing', function (assert) {
                    var object = new TorusKnotGeometry();
                    assert.ok(object, 'Can instantiate a TorusKnotGeometry.');
                });

                // PROPERTIES
                QUnit.test('type', function (assert) {
                    var object = new TorusKnotGeometry();
                    assert.ok(object.type == 'TorusKnotGeometry', 'TorusKnotGeometry.type should be TorusKnotGeometry');
                });

                QUnit.todo('parameters', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // STATIC
                QUnit.todo('fromJSON', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // OTHERS
                QUnit.test('Standard geometry tests', function (assert) {
                    runStdGeometryTests(assert, geometries);
                });
            });
        });
    }
}

_TorusKnotGeometryTest.test();