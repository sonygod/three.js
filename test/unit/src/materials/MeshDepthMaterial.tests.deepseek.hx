package three.js.test.unit.src.materials;

import three.js.src.materials.MeshDepthMaterial;
import three.js.src.materials.Material;

class MeshDepthMaterialTests {

    static function main() {

        // INHERITANCE
        var object = new MeshDepthMaterial();
        unittest.assert(object instanceof Material);

        // INSTANCING
        object = new MeshDepthMaterial();
        unittest.assert(object != null);

        // PROPERTIES
        object = new MeshDepthMaterial();
        unittest.assert(object.type == "MeshDepthMaterial");

        // TODO: depthPacking, map, alphaMap, displacementMap, displacementScale, displacementBias, wireframe, wireframeLinewidth

        // PUBLIC
        object = new MeshDepthMaterial();
        unittest.assert(object.isMeshDepthMaterial);

        // TODO: copy

    }

}