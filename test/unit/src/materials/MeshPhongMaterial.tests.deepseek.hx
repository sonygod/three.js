package three.test.unit.src.materials;

import three.src.materials.MeshPhongMaterial;
import three.src.materials.Material;
import js.Lib;

class MeshPhongMaterialTests {

    public static function main() {
        // INHERITANCE
        var object = new MeshPhongMaterial();
        Lib.assert(object instanceof Material, "MeshPhongMaterial extends from Material");

        // INSTANCING
        object = new MeshPhongMaterial();
        Lib.assert(object != null, "Can instantiate a MeshPhongMaterial.");

        // PROPERTIES
        object = new MeshPhongMaterial();
        Lib.assert(object.type == "MeshPhongMaterial", "MeshPhongMaterial.type should be MeshPhongMaterial");

        // TODO: Add the rest of the tests here

        // PUBLIC
        object = new MeshPhongMaterial();
        Lib.assert(object.isMeshPhongMaterial, "MeshPhongMaterial.isMeshPhongMaterial should be true");

        // TODO: Add the rest of the tests here
    }
}