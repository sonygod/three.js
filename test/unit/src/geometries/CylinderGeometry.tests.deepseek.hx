package three.js.test.unit.src.geometries;

import three.js.src.geometries.CylinderGeometry;
import three.js.src.core.BufferGeometry;
import three.js.utils.qunit_utils.runStdGeometryTests;

class CylinderGeometryTests {

    static function main() {

        var geometries:Array<CylinderGeometry>;

        var parameters = {
            radiusTop: 10,
            radiusBottom: 20,
            height: 30,
            radialSegments: 20,
            heightSegments: 30,
            openEnded: true,
            thetaStart: 0.1,
            thetaLength: 2.0,
        };

        geometries = [
            new CylinderGeometry(),
            new CylinderGeometry(parameters.radiusTop),
            new CylinderGeometry(parameters.radiusTop, parameters.radiusBottom),
            new CylinderGeometry(parameters.radiusTop, parameters.radiusBottom, parameters.height),
            new CylinderGeometry(parameters.radiusTop, parameters.radiusBottom, parameters.height, parameters.radialSegments),
            new CylinderGeometry(parameters.radiusTop, parameters.radiusBottom, parameters.height, parameters.radialSegments, parameters.heightSegments),
            new CylinderGeometry(parameters.radiusTop, parameters.radiusBottom, parameters.height, parameters.radialSegments, parameters.heightSegments, parameters.openEnded),
            new CylinderGeometry(parameters.radiusTop, parameters.radiusBottom, parameters.height, parameters.radialSegments, parameters.heightSegments, parameters.openEnded, parameters.thetaStart),
            new CylinderGeometry(parameters.radiusTop, parameters.radiusBottom, parameters.height, parameters.radialSegments, parameters.heightSegments, parameters.openEnded, parameters.thetaStart, parameters.thetaLength),
        ];

        // INHERITANCE
        var object = new CylinderGeometry();
        unittest.assert(object instanceof BufferGeometry);

        // INSTANCING
        var object = new CylinderGeometry();
        unittest.assert(object != null);

        // PROPERTIES
        var object = new CylinderGeometry();
        unittest.assert(object.type == "CylinderGeometry");

        // STATIC
        // TODO

        // OTHERS
        runStdGeometryTests(geometries);

    }

}