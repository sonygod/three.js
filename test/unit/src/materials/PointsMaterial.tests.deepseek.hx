package three.js.test.unit.src.materials;

import three.js.src.materials.PointsMaterial;
import three.js.src.materials.Material;

class PointsMaterialTests {

    static function main() {
        // INHERITANCE
        var object = new PointsMaterial();
        unittest.assert(object instanceof Material);

        // INSTANCING
        var object = new PointsMaterial();
        unittest.assert(object != null);

        // PROPERTIES
        var object = new PointsMaterial();
        unittest.assert(object.type == "PointsMaterial");

        // TODO: color, map, alphaMap, size, sizeAttenuation, fog

        // PUBLIC
        var object = new PointsMaterial();
        unittest.assert(object.isPointsMaterial);

        // TODO: copy
    }
}