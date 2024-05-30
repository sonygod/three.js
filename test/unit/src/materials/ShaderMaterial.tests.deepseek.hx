package three.js.test.unit.src.materials;

import three.js.src.materials.ShaderMaterial;
import three.js.src.materials.Material;

class ShaderMaterialTests {

    static function main() {
        // INHERITANCE
        var object = new ShaderMaterial();
        unittest.assert(object instanceof Material);

        // INSTANCING
        var object = new ShaderMaterial();
        unittest.assert(object != null);

        // PROPERTIES
        var object = new ShaderMaterial();
        unittest.assert(object.type == "ShaderMaterial");

        // TODO: Add remaining tests
    }
}