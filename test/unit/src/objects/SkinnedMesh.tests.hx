package three.test.unit.src.objects;

import three.core.Object3D;
import three.objects.Mesh;
import three.objects.SkinnedMesh;
import three.constants.AttachedBindMode;

class SkinnedMeshTests {
    public static function main() {
        suite("Objects", () => {
            suite("SkinnedMesh", () => {
                // INHERITANCE
                test("Extending", () => {
                    var skinnedMesh:SkinnedMesh = new SkinnedMesh();
                    assertTrue(skinnedMesh instanceof Object3D, "SkinnedMesh extends from Object3D");
                    assertTrue(skinnedMesh instanceof Mesh, "SkinnedMesh extends from Mesh");
                });

                // INSTANCING
                test("Instancing", () => {
                    var object:SkinnedMesh = new SkinnedMesh();
                    assertTrue(object != null, "Can instantiate a SkinnedMesh.");
                });

                // PROPERTIES
                test("type", () => {
                    var object:SkinnedMesh = new SkinnedMesh();
                    assertEquals(object.type, "SkinnedMesh", "SkinnedMesh.type should be SkinnedMesh");
                });

                test("bindMode", () => {
                    var object:SkinnedMesh = new SkinnedMesh();
                    assertEquals(object.bindMode, AttachedBindMode, "SkinnedMesh.bindMode should be AttachedBindMode");
                });

                todo("bindMatrix", () => {
                    assertTrue(false, "everything's gonna be alright");
                });

                todo("bindMatrixInverse", () => {
                    assertTrue(false, "everything's gonna be alright");
                });

                // PUBLIC
                test("isSkinnedMesh", () => {
                    var object:SkinnedMesh = new SkinnedMesh();
                    assertTrue(object.isSkinnedMesh, "SkinnedMesh.isSkinnedMesh should be true");
                });

                todo("copy", () => {
                    assertTrue(false, "everything's gonna be alright");
                });

                todo("bind", () => {
                    assertTrue(false, "everything's gonna be alright");
                });

                todo("pose", () => {
                    assertTrue(false, "everything's gonna be alright");
                });

                todo("normalizeSkinWeights", () => {
                    assertTrue(false, "everything's gonna be alright");
                });

                todo("updateMatrixWorld", () => {
                    assertTrue(false, "everything's gonna be alright");
                });

                todo("applyBoneTransform", () => {
                    assertTrue(false, "everything's gonna be alright");
                });
            });
        });
    }
}