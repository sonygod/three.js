package three.js.test.unit.src.geometries;

import three.js.src.core.BufferGeometry;
import three.js.src.geometries.RingGeometry;
import three.js.utils.qunit.QUnit;
import three.js.utils.qunit.runStdGeometryTests;

class RingGeometryTests {

    public static function main():Void {
        QUnit.module('Geometries', () -> {
            QUnit.module('RingGeometry', (hooks) -> {
                var geometries:Array<RingGeometry>;
                hooks.beforeEach(() -> {
                    var parameters = {
                        innerRadius: 10,
                        outerRadius: 60,
                        thetaSegments: 12,
                        phiSegments: 14,
                        thetaStart: 0.1,
                        thetaLength: 2.0
                    };

                    geometries = [
                        new RingGeometry(),
                        new RingGeometry(parameters.innerRadius),
                        new RingGeometry(parameters.innerRadius, parameters.outerRadius),
                        new RingGeometry(parameters.innerRadius, parameters.outerRadius, parameters.thetaSegments),
                        new RingGeometry(parameters.innerRadius, parameters.outerRadius, parameters.thetaSegments, parameters.phiSegments),
                        new RingGeometry(parameters.innerRadius, parameters.outerRadius, parameters.thetaSegments, parameters.phiSegments, parameters.thetaStart),
                        new RingGeometry(parameters.innerRadius, parameters.outerRadius, parameters.thetaSegments, parameters.phiSegments, parameters.thetaStart, parameters.thetaLength),
                    ];
                });

                // INHERITANCE
                QUnit.test('Extending', (assert) -> {
                    var object = new RingGeometry();
                    assert.strictEqual(
                        Std.is(object, BufferGeometry), true,
                        'RingGeometry extends from BufferGeometry'
                    );
                });

                // INSTANCING
                QUnit.test('Instancing', (assert) -> {
                    var object = new RingGeometry();
                    assert.ok(object, 'Can instantiate a RingGeometry.');
                });

                // PROPERTIES
                QUnit.test('type', (assert) -> {
                    var object = new RingGeometry();
                    assert.ok(
                        object.type == 'RingGeometry',
                        'RingGeometry.type should be RingGeometry'
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