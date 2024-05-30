package three.js.test.unit.src.materials;

import three.js.src.materials.RawShaderMaterial;
import three.js.src.materials.ShaderMaterial;

class RawShaderMaterialTests {

    public static function main() {
        // INHERITANCE
        var object = new RawShaderMaterial();
        unittest.assert(object instanceof ShaderMaterial);

        // INSTANCING
        var object = new RawShaderMaterial();
        unittest.assert(object != null);

        // PROPERTIES
        var object = new RawShaderMaterial();
        unittest.assert(object.type == "RawShaderMaterial");

        // PUBLIC
        var object = new RawShaderMaterial();
        unittest.assert(object.isRawShaderMaterial);
    }
}