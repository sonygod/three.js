package three.js.test.unit.src.materials;

import three.js.src.materials.MeshStandardMaterial;
import three.js.src.materials.Material;

class MeshStandardMaterialTests {

    public static function main() {
        // INHERITANCE
        var object = new MeshStandardMaterial();
        unittest.assert(object instanceof Material);

        // INSTANCING
        object = new MeshStandardMaterial();
        unittest.assert(object != null);

        // PROPERTIES
        // TODO: implement tests for defines, color, roughness, metalness, map, lightMap, lightMapIntensity, aoMap, aoMapIntensity, emissive, emissiveIntensity, emissiveMap, bumpMap, bumpScale, normalMap, normalMapType, normalScale, displacementMap, displacementScale, displacementBias, roughnessMap, metalnessMap, alphaMap, envMap, envMapIntensity, wireframe, wireframeLinewidth, wireframeLinecap, wireframeLinejoin, flatShading, fog

        // PUBLIC
        unittest.assert(object.isMeshStandardMaterial);
        // TODO: implement tests for copy
    }
}