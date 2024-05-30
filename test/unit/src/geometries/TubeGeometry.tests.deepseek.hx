package three.js.test.unit.src.geometries;

import three.js.src.geometries.TubeGeometry;
import three.js.src.extras.curves.LineCurve3;
import three.js.src.math.Vector3;
import three.js.src.core.BufferGeometry;

class TubeGeometryTests {
    static function main() {
        var path = new LineCurve3(new Vector3(0, 0, 0), new Vector3(0, 1, 0));
        var geometries = [new TubeGeometry(path)];

        // INHERITANCE
        var object = new TubeGeometry();
        unittest.assert(object instanceof BufferGeometry);

        // INSTANCING
        object = new TubeGeometry();
        unittest.assert(object != null);

        // PROPERTIES
        object = new TubeGeometry();
        unittest.assert(object.type == "TubeGeometry");

        // TODO: parameters, tangents, normals, binormals, toJSON, fromJSON, Standard geometry tests
    }
}