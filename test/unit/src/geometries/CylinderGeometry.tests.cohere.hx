package;

import js.QUnit;
import js.geom.CylinderGeometry;
import js.core.BufferGeometry;
import js.utils.qunit.runStdGeometryTests;

@:isTest
class Main {
    static function main() {
        var geometries:Array<CylinderGeometry> = [];
        var parameters = {
            radiusTop: 10,
            radiusBottom: 20,
            height: 30,
            radialSegments: 20,
            heightSegments: 30,
            openEnded: true,
            thetaStart: 0.1,
            thetaLength: 2.0
        };

        QUnit.module('Geometries', function () {
            QUnit.module('CylinderGeometry', function (hooks) {
                hooks.beforeEach(function () {
                    geometries = [
                        new CylinderGeometry(),
                        new CylinderGeometry(parameters.radiusTop),
                        new CylinderGeometry(parameters.radiusTop, parameters.radiusBottom),
                        new CylinderGeometry(parameters.radiusTop, parameters.radiusBottom, parameters.height),
                        new CylinderGeometry(parameters.radiusTop, parameters.radiusBottom, parameters.height, parameters.radialSegments),
                        new CylinderGeometry(parameters.radiusTop, parameters.radiusBottom, parameters.height, parameters.radialSegments, parameters.heightSegments),
                        new CylinderGeometry(parameters.radiusTop, parameters.radiusBottom, parameters.height, parameters.radialSegments, parameters.heightSegments, parameters.openEnded),
                        new CylinderGeometry(parameters.radiusTop, parameters.radiusBottom, parameters.height, parameters.radialSegments, parameters.heightSegments, parameters.openEnded, parameters.thetaStart),
                        new CylinderGeometry(parameters.radiusTop, parameters.radiusBottom, parameters.height, parameters.radialSegments, parameters.heightSegments, parameters.openEnded, parameters.thetaStart, parameters.thetaLength)
                    ];
                });

                // INHERITANCE
                QUnit.test('Extending', function (assert) {
                    var object = new CylinderGeometry();
                    assert.strictEqual(object instanceof BufferGeometry, true, 'CylinderGeometry extends from BufferGeometry');
                });

                // INSTANCING
                QUnit.test('Instancing', function (assert) {
                    var object = new CylinderGeometry();
                    assert.ok(object, 'Can instantiate a CylinderGeometry.');
                });

                // PROPERTIES
                QUnit.test('type', function (assert) {
                    var object = new CylinderGeometry();
                    assert.ok(object.type == 'CylinderGeometry', 'CylinderGeometry.type should be CylinderGeometry');
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