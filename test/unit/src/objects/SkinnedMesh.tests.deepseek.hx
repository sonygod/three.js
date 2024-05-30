package three.js.test.unit.src.objects;

import three.js.src.core.Object3D;
import three.js.src.objects.Mesh;
import three.js.src.objects.SkinnedMesh;
import three.js.src.constants.AttachedBindMode;

class SkinnedMeshTests {

    public static function main() {
        // INHERITANCE
        var skinnedMesh = new SkinnedMesh();
        unittest.assert(skinnedMesh is Object3D);
        unittest.assert(skinnedMesh is Mesh);

        // INSTANCING
        var object = new SkinnedMesh();
        unittest.assert(object != null);

        // PROPERTIES
        unittest.assert(object.type == "SkinnedMesh");
        unittest.assert(object.bindMode == AttachedBindMode);

        // PUBLIC
        unittest.assert(object.isSkinnedMesh);
    }
}