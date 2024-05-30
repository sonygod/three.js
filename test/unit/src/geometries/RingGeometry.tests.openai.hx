package three.js.test.unit.src.geometries;

import three.js.geometries.RingGeometry;
import three.js.core.BufferGeometry;
import three.js.utils.QUnitUtils;

class RingGeometryTests {

    public function new() {}

    public static function main() {
        QUnit.module("Geometries", function() {
            QUnit.module("RingGeometry", function(hooks) {
                var geometries:Array<RingGeometry> = null;
                hooks.beforeEach(function() {
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
                QUnit.test("Extending", function(assert) {
                    var object:BufferGeometry = new RingGeometry();
                    assert.ok(object instanceof BufferGeometry, "RingGeometry extends from BufferGeometry");
                });

                // INSTANCING
                QUnit.test("Instancing", function(assert) {
                    var object:RingGeometry = new RingGeometry();
                    assert.ok(object, 'Can instantiate a RingGeometry.');
                });

                // PROPERTIES
                QUnit.test("type", function(assert) {
                    var object:RingGeometry = new RingGeometry();
                    assert.ok(object.type == "RingGeometry", 'RingGeometry.type should be RingGeometry');
                });

                QUnit.todo("parameters", function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // STATIC
                QUnit.todo("fromJSON", function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // OTHERS
                QUnit.test("Standard geometry tests", function(assert) {
                    QUnitUtils.runStdGeometryTests(assert, geometries);
                });
            });
        });
    }
}