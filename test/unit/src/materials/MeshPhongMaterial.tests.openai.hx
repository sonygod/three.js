import haxe.unit.TestCase;

import materials.MeshPhongMaterial;
import materials.Material;

class MeshPhongMaterialTests {
    public static function main() {
        var testCase = new TestCase();
        testCase.test("Inheritance", function(assert) {
            var object = new MeshPhongMaterial();
            assert.isTrue(object instanceof Material, "MeshPhongMaterial extends from Material");
        });

        testCase.test("Instancing", function(assert) {
            var object = new MeshPhongMaterial();
            assert.notNull(object, "Can instantiate a MeshPhongMaterial.");
        });

        testCase.test("type", function(assert) {
            var object = new MeshPhongMaterial();
            assert.equals(object.type, "MeshPhongMaterial", "MeshPhongMaterial.type should be MeshPhongMaterial");
        });

        // todo: implement the rest of the tests...

        var todoTests = [
            "color",
            "specular",
            "shininess",
            "map",
            "lightMap",
            "lightMapIntensity",
            "aoMap",
            "aoMapIntensity",
            "emissive",
            "emissiveIntensity",
            "emissiveMap",
            "bumpMap",
            "bumpScale",
            "normalMap",
            "normalMapType",
            "normalScale",
            "displacementMap",
            "displacementScale",
            "displacementBias",
            "specularMap",
            "alphaMap",
            "envMap",
            "combine",
            "reflectivity",
            "refractionRatio",
            "wireframe",
            "wireframeLinewidth",
            "wireframeLinecap",
            "wireframeLinejoin",
            "flatShading",
            "fog",
            "isMeshPhongMaterial",
            "copy",
        ];

        for (test in todoTests) {
            testCase.test(test, function(assert) {
                assert.fail("Not implemented");
            });
        }
    }
}