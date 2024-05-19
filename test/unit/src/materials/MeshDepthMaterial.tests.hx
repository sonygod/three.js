package three.test.unit.src.materials;

import three.materials.MeshDepthMaterial;
import three.materials.Material;

class MeshDepthMaterialTests {

    public function new() {}

    public static function main() {
        QUnit.module("Materials", () => {
            QUnit.module("MeshDepthMaterial", () => {
                // INHERITANCE
                QUnit.test("Extending", (assert) => {
                    var object = new MeshDepthMaterial();
                    assert.isTrue(object instanceof Material, "MeshDepthMaterial extends from Material");
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) => {
                    var object = new MeshDepthMaterial();
                    assert.ok(object, "Can instantiate a MeshDepthMaterial.");
                });

                // PROPERTIES
                QUnit.test("type", (assert) => {
                    var object = new MeshDepthMaterial();
                    assert.ok(object.type == "MeshDepthMaterial", "MeshDepthMaterial.type should be MeshDepthMaterial");
                });

                QUnit.todo("depthPacking", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("map", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("alphaMap", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("displacementMap", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("displacementScale", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("displacementBias", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("wireframe", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("wireframeLinewidth", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                // PUBLIC
                QUnit.test("isMeshDepthMaterial", (assert) => {
                    var object = new MeshDepthMaterial();
                    assert.ok(object.isMeshDepthMaterial, "MeshDepthMaterial.isMeshDepthMaterial should be true");
                });

                QUnit.todo("copy", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });
            });
        });
    }
}