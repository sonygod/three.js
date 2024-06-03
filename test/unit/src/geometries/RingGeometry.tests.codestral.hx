import three.geometries.RingGeometry;
import three.core.BufferGeometry;

class RingGeometryTests {

    static public function main() {
        trace("Geometries > RingGeometry");

        var geometries:Array<RingGeometry> = [];

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
            new RingGeometry(parameters.innerRadius, parameters.outerRadius, parameters.thetaSegments, parameters.phiSegments, parameters.thetaStart, parameters.thetaLength)
        ];

        testExtending();
        testInstancing();
        testType();

        // Call other tests here
    }

    static private function testExtending() {
        var object:RingGeometry = new RingGeometry();
        trace("RingGeometry extends from BufferGeometry: " + Std.is(object, BufferGeometry));
    }

    static private function testInstancing() {
        var object:RingGeometry = new RingGeometry();
        trace("Can instantiate a RingGeometry: " + (object != null));
    }

    static private function testType() {
        var object:RingGeometry = new RingGeometry();
        trace("RingGeometry.type should be RingGeometry: " + (object.type == "RingGeometry"));
    }

    // Add other test functions here
}