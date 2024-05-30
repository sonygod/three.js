package three.test.unit.src.materials;

import three.src.materials.MeshLambertMaterial;
import three.src.materials.Material;
import js.Lib;

class MeshLambertMaterialTests {
    static function main() {
        // INHERITANCE
        var object = new MeshLambertMaterial();
        Lib.assert(object instanceof Material, "MeshLambertMaterial extends from Material");

        // INSTANCING
        object = new MeshLambertMaterial();
        Lib.assert(object != null, "Can instantiate a MeshLambertMaterial.");

        // PROPERTIES
        object = new MeshLambertMaterial();
        Lib.assert(object.type == "MeshLambertMaterial", "MeshLambertMaterial.type should be MeshLambertMaterial");

        // TODO: Add the rest of the tests here

        // PUBLIC
        object = new MeshLambertMaterial();
        Lib.assert(object.isMeshLambertMaterial, "MeshLambertMaterial.isMeshLambertMaterial should be true");

        // TODO: Add the rest of the tests here
    }
}