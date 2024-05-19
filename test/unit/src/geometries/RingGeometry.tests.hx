package three.js.test.unit.src.geometries;

import haxe.unit.TestCase;
import three.js.geometries.RingGeometry;
import three.js.core.BufferGeometry;
import three.js.utils.QUnitUtils;

class RingGeometryTests {
    public function new() {}

    public function test() {
        var geometries:Array<RingGeometry> = [];

        beforeEach(function() {
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

        TestCase.test("Extending", function(assert) {
            var object = new RingGeometry();
            assert.isTrue(object instanceof BufferGeometry, 'RingGeometry extends from BufferGeometry');
        });

        TestCase.test("Instancing", function(assert) {
            var object = new RingGeometry();
            assert.ok(object, 'Can instantiate a RingGeometry.');
        });

        TestCase.test("type", function(assert) {
            var object = new RingGeometry();
            assert.equals(object.type, 'RingGeometry', 'RingGeometry.type should be RingGeometry');
        });

        TestCase.test("parameters", function(assert) {
            // TODO: implement
            assert.ok(false, 'everything\'s gonna be alright');
        });

        TestCase.test("fromJSON", function(assert) {
            // TODO: implement
            assert.ok(false, 'everything\'s gonna be alright');
        });

        TestCase.test("Standard geometry tests", function(assert) {
            QUnitUtils.runStdGeometryTests(assert, geometries);
        });
    }
}