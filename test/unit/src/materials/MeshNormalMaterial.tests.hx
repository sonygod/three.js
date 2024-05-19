package three.test.unit.src.materials;

import three.materials.MeshNormalMaterial;
import three.materials.Material;

class MeshNormalMaterialTests {
    public function new() {}

    public static function main() {
        var suite = new TestSuite("Materials");

        suite.addTest(new Test("MeshNormalMaterial", function(assert) {
            // INHERITANCE
            assert.test("Extending", function(assert) {
                var object = new MeshNormalMaterial();
                assert.isTrue(Std.is(object, Material), "MeshNormalMaterial extends from Material");
            });

            // INSTANCING
            assert.test("Instancing", function(assert) {
                var object = new MeshNormalMaterial();
                assert.isTrue(object != null, "Can instantiate a MeshNormalMaterial.");
            });

            // PROPERTIES
            assert.test("type", function(assert) {
                var object = new MeshNormalMaterial();
                assert.equals(object.type, "MeshNormalMaterial", "MeshNormalMaterial.type should be MeshNormalMaterial");
            });

            // TODOs
            assert.todo("bumpMap", function(assert) {
                assert.fail("everything's gonna be alright");
            });

            assert.todo("bumpScale", function(assert) {
                assert.fail("everything's gonna be alright");
            });

            assert.todo("normalMap", function(assert) {
                assert.fail("everything's gonna be alright");
            });

            assert.todo("normalMapType", function(assert) {
                assert.fail("everything's gonna be alright");
            });

            assert.todo("normalScale", function(assert) {
                assert.fail("everything's gonna be alright");
            });

            assert.todo("displacementMap", function(assert) {
                assert.fail("everything's gonna be alright");
            });

            assert.todo("displacementScale", function(assert) {
                assert.fail("everything's gonna be alright");
            });

            assert.todo("displacementBias", function(assert) {
                assert.fail("everything's gonna be alright");
            });

            assert.todo("wireframe", function(assert) {
                assert.fail("everything's gonna be alright");
            });

            assert.todo("wireframeLinewidth", function(assert) {
                assert.fail("everything's gonna be alright");
            });

            assert.todo("flatShading", function(assert) {
                assert.fail("everything's gonna be alright");
            });

            // PUBLIC
            assert.test("isMeshNormalMaterial", function(assert) {
                var object = new MeshNormalMaterial();
                assert.isTrue(object.isMeshNormalMaterial, "MeshNormalMaterial.isMeshNormalMaterial should be true");
            });

            assert.todo("copy", function(assert) {
                assert.fail("everything's gonna be alright");
            });
        }));
    }
}