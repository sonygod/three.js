package three.js.test.unit.src.geometries;

import haxe.unit.TestCase;
import three.js.geometries.CircleGeometry;
import three.js.core.BufferGeometry;
import three.js.utils.QUnitUtils;

class CircleGeometryTests {
    public function new() {}

    public static function main() {
        var testCase = new CircleGeometryTests();
        testCase.test();
    }

    private function test() {
        var geometries:Array<BufferGeometry> = [];

        beforeEach(function () {
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
        testCase("Extending", function (assert) {
            var object = new CircleGeometry();
            assert.isTrue(object instanceof BufferGeometry, 'CircleGeometry extends from BufferGeometry');
        });

        // INSTANCING
        testCase("Instancing", function (assert) {
            var object = new CircleGeometry();
            assert.isTrue(object != null, 'Can instantiate a CircleGeometry.');
        });

        // PROPERTIES
        testCase("type", function (assert) {
            var object = new CircleGeometry();
            assert.equals(object.type, 'CircleGeometry', 'CircleGeometry.type should be CircleGeometry');
        });

        // TODO: implement parameters test
        //testCase("parameters", function (assert) {
        //    assert.ok(false, 'everything\'s gonna be alright');
        //});

        // TODO: implement fromJSON test
        //testCase("fromJSON", function (assert) {
        //    assert.ok(false, 'everything\'s gonna be alright');
        //});

        // OTHERS
        testCase("Standard geometry tests", function (assert) {
            QUnitUtils.runStdGeometryTests(assert, geometries);
        });
    }
}