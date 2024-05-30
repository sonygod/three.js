package;

import three.js.test.unit.src.geometries.SphereGeometry;
import three.js.test.unit.src.core.BufferGeometry;
import three.js.test.unit.utils.qunit_utils.runStdGeometryTests;

class SphereGeometryTests {

    static function main() {

        var geometries:Array<SphereGeometry>;

        var parameters = {
            radius: 10,
            widthSegments: 20,
            heightSegments: 30,
            phiStart: 0.5,
            phiLength: 1.0,
            thetaStart: 0.4,
            thetaLength: 2.0,
        };

        geometries = [
            new SphereGeometry(),
            new SphereGeometry(parameters.radius),
            new SphereGeometry(parameters.radius, parameters.widthSegments),
            new SphereGeometry(parameters.radius, parameters.widthSegments, parameters.heightSegments),
            new SphereGeometry(parameters.radius, parameters.widthSegments, parameters.heightSegments, parameters.phiStart),
            new SphereGeometry(parameters.radius, parameters.widthSegments, parameters.heightSegments, parameters.phiStart, parameters.phiLength),
            new SphereGeometry(parameters.radius, parameters.widthSegments, parameters.heightSegments, parameters.phiStart, parameters.phiLength, parameters.thetaStart),
            new SphereGeometry(parameters.radius, parameters.widthSegments, parameters.heightSegments, parameters.phiStart, parameters.phiLength, parameters.thetaStart, parameters.thetaLength),
        ];

        // INHERITANCE
        var object = new SphereGeometry();
        unittest.assert(object instanceof BufferGeometry);

        // INSTANCING
        object = new SphereGeometry();
        unittest.assert(object != null);

        // PROPERTIES
        object = new SphereGeometry();
        unittest.assert(object.type == "SphereGeometry");

        // STATIC
        // TODO: Implement static tests

        // OTHERS
        runStdGeometryTests(geometries);

    }

}