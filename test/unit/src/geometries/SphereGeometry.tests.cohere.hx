import js.QUnit;
import js.BufferGeometry;

import js.SphereGeometry.new;
import js.SphereGeometry.parameters;

import qunitutils.runStdGeometryTests;

class _Main {
    static function main() {
        var geometries:Array<SphereGeometry>;

        var parameters = {
            radius: 10,
            widthSegments: 20,
            heightSegments: 30,
            phiStart: 0.5,
            phiLength: 1.0,
            thetaStart: 0.4,
            thetaLength: 2.0
        };

        QUnit.module('Geometries > SphereGeometry', function (hooks) {
            hooks.beforeEach(function () {
                geometries = [
                    new SphereGeometry(),
                    new SphereGeometry(parameters.radius),
                    new SphereGeometry(parameters.radius, parameters.widthSegments),
                    new SphereGeometry(parameters.radius, parameters.widthSegments, parameters.heightSegments),
                    new SphereGeometry(parameters.radius, parameters.widthSegments, parameters.heightSegments, parameters.phiStart),
                    new SphereGeometry(parameters.radius, parameters.widthSegments, parameters.heightSegments, parameters.phiStart, parameters.phiLength),
                    new SphereGeometry(parameters.radius, parameters.widthSegments, parameters.heightSegments, parameters.phiStart, parameters.phiLength, parameters.thetaStart),
                    new SphereGeometry(parameters.radius, parameters.widthSegments, parameters.heightSegments, parameters.phiStart, parameters.phiLength, parameters.thetaStart, parameters.thetaLength)
                ];
            });

            // INHERITANCE
            QUnit.test('Extending', function (assert) {
                var object = new SphereGeometry();
                assert.strictEqual(object instanceof BufferGeometry, true, 'SphereGeometry extends from BufferGeometry');
            });

            // INSTANCING
            QUnit.test('Instancing', function (assert) {
                var object = new SphereGeometry();
                assert.ok(object, 'Can instantiate a SphereGeometry.');
            });

            // PROPERTIES
            QUnit.test('type', function (assert) {
                var object = new SphereGeometry();
                assert.ok(object.type == 'SphereGeometry', 'SphereGeometry.type should be SphereGeometry');
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
    }
}