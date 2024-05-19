package three.test.unit.src.materials;

import three.materials.MeshBasicMaterial;
import three.materials.Material;

class MeshBasicMaterialTests {
    public function new() {}

    public static function main() {
        // INHERITANCE
        QUnit.test("Extending", (assert) -> {
            var object = new MeshBasicMaterial();
            assert.isTrue(object instanceof Material, "MeshBasicMaterial extends from Material");
        });

        // INSTANCING
        QUnit.test("Instancing", (assert) -> {
            var object = new MeshBasicMaterial();
            assert.ok(object, 'Can instantiate a MeshBasicMaterial.');
        });

        // PROPERTIES
        QUnit.test("type", (assert) -> {
            var object = new MeshBasicMaterial();
            assert.ok(object.type == 'MeshBasicMaterial', 'MeshBasicMaterial.type should be MeshBasicMaterial');
        });

        // TODOs
        QUnit.todo("color", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("map", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("lightMap", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("lightMapIntensity", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("aoMap", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("aoMapIntensity", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("specularMap", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("alphaMap", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("envMap", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("combine", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("reflectivity", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("refractionRatio", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("wireframe", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("wireframeLinewidth", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("wireframeLinecap", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("wireframeLinejoin", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("fog", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
        });

        // PUBLIC
        QUnit.test("isMeshBasicMaterial", (assert) -> {
            var object = new MeshBasicMaterial();
            assert.ok(object.isMeshBasicMaterial, 'MeshBasicMaterial.isMeshBasicMaterial should be true');
        });

        QUnit.todo("copy", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
        });
    }
}