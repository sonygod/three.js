package three.js.test.unit.src.geometries;

import three.js.src.geometries.ShapeGeometry;
import three.js.src.extras.core.Shape;
import three.js.src.core.BufferGeometry;

class ShapeGeometryTests {

    public static function main() {
        var triangleShape = new Shape();
        triangleShape.moveTo(0, -1);
        triangleShape.lineTo(1, 1);
        triangleShape.lineTo(-1, 1);

        var geometries = [new ShapeGeometry(triangleShape)];

        // INHERITANCE
        var object = new ShapeGeometry();
        unittest.assert(object instanceof BufferGeometry);

        // INSTANCING
        var object = new ShapeGeometry();
        unittest.assert(object != null);

        // PROPERTIES
        var object = new ShapeGeometry();
        unittest.assert(object.type == "ShapeGeometry");

        // TODO: parameters

        // TODO: toJSON

        // TODO: fromJSON

        // TODO: Standard geometry tests
    }
}