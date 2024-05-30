package materials;

import three.js.Material;

class MeshDepthMaterialTests {

    public function new() {}

    public function test() {
        // INHERITANCE
        QUnit.test("Extending", function(assert) {
            var object = new MeshDepthMaterial();
            assertOK(object instanceof Material, "MeshDepthMaterial extends from Material");
        });

        // INSTANCING
        QUnit.test("Instancing", function(assert) {
            var object = new MeshDepthMaterial();
            assertOK(object != null, "Can instantiate a MeshDepthMaterial.");
        });

        // PROPERTIES
        QUnit.test("type", function(assert) {
            var object = new MeshDepthMaterial();
            assertOK(object.type == "MeshDepthMaterial", "MeshDepthMaterial.type should be MeshDepthMaterial");
        });

        QUnit.todo("depthPacking", function(assert) {
            assertOK(false, "everything's gonna be alright");
        });

        QUnit.todo("map", function(assert) {
            assertOK(false, "everything's gonna be alright");
        });

        QUnit.todo("alphaMap", function(assert) {
            assertOK(false, "everything's gonna be alright");
        });

        QUnit.todo("displacementMap", function(assert) {
            assertOK(false, "everything's gonna be alright");
        });

        QUnit.todo("displacementScale", function(assert) {
            assertOK(false, "everything's gonna be alright");
        });

        QUnit.todo("displacementBias", function(assert) {
            assertOK(false, "everything's gonna be alright");
        });

        QUnit.todo("wireframe", function(assert) {
            assertOK(false, "everything's gonna be alright");
        });

        QUnit.todo("wireframeLinewidth", function(assert) {
            assertOK(false, "everything's gonna be alright");
        });

        // PUBLIC
        QUnit.test("isMeshDepthMaterial", function(assert) {
            var object = new MeshDepthMaterial();
            assertOK(object.isMeshDepthMaterial, "MeshDepthMaterial.isMeshDepthMaterial should be true");
        });

        QUnit.todo("copy", function(assert) {
            assertOK(false, "everything's gonna be alright");
        });
    }
}