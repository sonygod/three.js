package three.materials;

import haxe.unit.TestCase;
import three.materials.MeshPhysicalMaterial;
import three.materials.Material;

class MeshPhysicalMaterialTest {
    public function new() {}

    public function test() {
        // INHERITANCE
        testCase("Extending", function(assert) {
            var object = new MeshPhysicalMaterial();
            assert.isTrue(object instanceof Material, "MeshPhysicalMaterial extends from Material");
        });

        // INSTANCING
        testCase("Instancing", function(assert) {
            var object = new MeshPhysicalMaterial();
            assert.notNull(object, "Can instantiate a MeshPhysicalMaterial.");
        });

        // PROPERTIES
        todoTest("defines", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        testCase("type", function(assert) {
            var object = new MeshPhysicalMaterial();
            assert.equals(object.type, "MeshPhysicalMaterial", "MeshPhysicalMaterial.type should be MeshPhysicalMaterial");
        });

        todoTest("clearcoatMap", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        todoTest("clearcoatRoughness", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        todoTest("clearcoatRoughnessMap", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        todoTest("clearcoatNormalScale", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        todoTest("clearcoatNormalMap", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        todoTest("ior", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        todoTest("reflectivity", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        todoTest("iridescenceMap", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        todoTest("iridescenceIOR", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        todoTest("iridescenceThicknessRange", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        todoTest("iridescenceThicknessMap", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        todoTest("sheenColor", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        todoTest("sheenColorMap", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        todoTest("sheenRoughness", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        todoTest("sheenRoughnessMap", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        todoTest("transmissionMap", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        todoTest("thickness", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        todoTest("thicknessMap", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        todoTest("attenuationDistance", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        todoTest("attenuationColor", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        todoTest("specularIntensity", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        todoTest("specularIntensityMap", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        todoTest("specularColor", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        todoTest("specularColorMap", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        todoTest("sheen", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        todoTest("clearcoat", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        todoTest("iridescence", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        todoTest("transmission", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        // PUBLIC
        testCase("isMeshPhysicalMaterial", function(assert) {
            var object = new MeshPhysicalMaterial();
            assert.isTrue(object.isMeshPhysicalMaterial, "MeshPhysicalMaterial.isMeshPhysicalMaterial should be true");
        });

        todoTest("copy", function(assert) {
            assert.fail("everything's gonna be alright");
        });
    }
}