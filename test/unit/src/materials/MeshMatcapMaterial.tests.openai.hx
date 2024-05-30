package three.materials.tests;

import three.materials.MeshMatcapMaterial;
import three.materials.Material;

class MeshMatcapMaterialTests {
    public function new() {}

    public static function main() {
        utest.ui.Report.create("Materials");

        utest.Test.create("MeshMatcapMaterial", {
            // INHERITANCE
            test("Extending", function(assert) {
                var object = new MeshMatcapMaterial();
                assert.isTrue(object instanceof Material, 'MeshMatcapMaterial extends from Material');
            });

            // INSTANCING
            test("Instancing", function(assert) {
                var object = new MeshMatcapMaterial();
                assert.notNull(object, 'Can instantiate a MeshMatcapMaterial.');
            });

            // PROPERTIES
            test("defines", function(assert) {
                var actual = new MeshMatcapMaterial().defines;
                var expected = { MATCAP: '' };
                assert.deepEqual(actual, expected, 'Contains a MATCAP definition.');
            });

            test("type", function(assert) {
                var object = new MeshMatcapMaterial();
                assert.equal(object.type, 'MeshMatcapMaterial', 'MeshMatcapMaterial.type should be MeshMatcapMaterial');
            });

            // Todo tests
            todo("color", function(assert) {
                assert.isTrue(false, "everything's gonna be alright");
            });

            todo("matcap", function(assert) {
                assert.isTrue(false, "everything's gonna be alright");
            });

            todo("map", function(assert) {
                assert.isTrue(false, "everything's gonna be alright");
            });

            todo("bumpMap", function(assert) {
                assert.isTrue(false, "everything's gonna be alright");
            });

            todo("bumpScale", function(assert) {
                assert.isTrue(false, "everything's gonna be alright");
            });

            todo("normalMap", function(assert) {
                assert.isTrue(false, "everything's gonna be alright");
            });

            todo("normalMapType", function(assert) {
                assert.isTrue(false, "everything's gonna be alright");
            });

            todo("normalScale", function(assert) {
                assert.isTrue(false, "everything's gonna be alright");
            });

            todo("displacementMap", function(assert) {
                assert.isTrue(false, "everything's gonna be alright");
            });

            todo("displacementScale", function(assert) {
                assert.isTrue(false, "everything's gonna be alright");
            });

            todo("displacementBias", function(assert) {
                assert.isTrue(false, "everything's gonna be alright");
            });

            todo("alphaMap", function(assert) {
                assert.isTrue(false, "everything's gonna be alright");
            });

            todo("flatShading", function(assert) {
                assert.isTrue(false, "everything's gonna be alright");
            });

            todo("fog", function(assert) {
                assert.isTrue(false, "everything's gonna be alright");
            });

            // PUBLIC
            test("isMeshMatcapMaterial", function(assert) {
                var object = new MeshMatcapMaterial();
                assert.isTrue(object.isMeshMatcapMaterial, 'MeshMatcapMaterial.isMeshMatcapMaterial should be true');
            });

            todo("copy", function(assert) {
                assert.isTrue(false, "everything's gonna be alright");
            });
        });
    }
}