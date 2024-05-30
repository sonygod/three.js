package three.js.test.unit.src.materials;

import three.js.src.materials.MeshDistanceMaterial;
import three.js.src.materials.Material;

class MeshDistanceMaterialTests {

    public static function main() {

        // INHERITANCE
        var object = new MeshDistanceMaterial();
        unittest.assert(object instanceof Material);

        // INSTANCING
        var object = new MeshDistanceMaterial();
        unittest.assert(object != null);

        // PROPERTIES
        var object = new MeshDistanceMaterial();
        unittest.assert(object.type == "MeshDistanceMaterial");

        // PUBLIC
        var object = new MeshDistanceMaterial();
        unittest.assert(object.isMeshDistanceMaterial);
    }
}