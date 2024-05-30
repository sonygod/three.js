package;

import js.QUnit.QUnit;
import js.QUnit.Module;

import js.Three.src.geometries.CircleGeometry;
import js.Three.src.core.BufferGeometry;
import js.Three.utils.qunit.qunit_utils.runStdGeometryTests;

class _Test_Geometries {
    static function run() {
        QUnit.module( 'Geometries', function (hooks) {
            QUnit.module('CircleGeometry', function (hooks) {
                var geometries;
                hooks.beforeEach(function () {
                    var parameters = {
                        radius: 10,
                        segments: 20,
                        thetaStart: 0.1,
                        thetaLength: 0.2
                    };
                    geometries = [
                        new CircleGeometry(),
                        new CircleGeometry(parameters.radius),
                        new CircleGeometry(parameters.radius, parameters.segments),
                        new CircleGeometry(parameters.radius, parameters.segments, parameters.thetaStart),
                        new CircleGeometry(parameters.radius, parameters.segments, parameters.thetaStart, parameters.thetaLength)
                    ];
                });

                // INHERITANCE
                QUnit.test('Extending', function (assert) {
                    var object = new CircleGeometry();
                    assert.strictEqual(object instanceof BufferGeometry, true, 'CircleGeometry extends from BufferGeometry');
                });

                // INSTANCING
                QUnit.test('Instancing', function (assert) {
                    var object = new CircleGeometry();
                    assert.ok(object, 'Can instantiate a CircleGeometry.');
                });

                // PROPERTIES
                QUnit.test('type', function (assert) {
                    var object = new CircleGeometry();
                    assert.ok(object.type == 'CircleGeometry', 'CircleGeometry.type should be CircleGeometry');
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

_Test_Geometries.run();