package three.js.test.unit.src.materials;

import three.js.src.materials.MeshToonMaterial;
import three.js.src.materials.Material;
import js.Lib;

class MeshToonMaterialTests {

    static function main() {
        // INHERITANCE
        var object = new MeshToonMaterial();
        Lib.assert(object instanceof Material, "MeshToonMaterial extends from Material");

        // INSTANCING
        object = new MeshToonMaterial();
        Lib.assert(object != null, "Can instantiate a MeshToonMaterial.");

        // PROPERTIES
        Lib.assert(object.type == "MeshToonMaterial", "MeshToonMaterial.type should be MeshToonMaterial");

        // PUBLIC
        Lib.assert(object.isMeshToonMaterial, "MeshToonMaterial.isMeshToonMaterial should be true");
    }
}