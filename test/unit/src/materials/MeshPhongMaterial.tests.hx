package three.test.unit.src.materials;

import three.materials.MeshPhongMaterial;
import three.materials.Material;

class MeshPhongMaterialTests {
    public function new() {}

    public static function main() {
        QUnit.module("Materials", function() {
            QUnit.module("MeshPhongMaterial", function() {
                // INHERITANCE
                QUnit.test("Extending", function(assert) {
                    var object = new MeshPhongMaterial();
                    assert.ok(object instanceof Material, "MeshPhongMaterial extends from Material");
                });

                // INSTANCING
                QUnit.test("Instancing", function(assert) {
                    var object = new MeshPhongMaterial();
                    assert.ok(object, "Can instantiate a MeshPhongMaterial.");
                });

                // PROPERTIES
                QUnit.test("type", function(assert) {
                    var object = new MeshPhongMaterial();
                    assert.ok(object.type == "MeshPhongMaterial", "MeshPhongMaterial.type should be MeshPhongMaterial");
                });

                QUnit.todo("color", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("specular", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("shininess", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("map", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("lightMap", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("lightMapIntensity", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("aoMap", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("aoMapIntensity", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("emissive", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("emissiveIntensity", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("emissiveMap", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("bumpMap", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("bumpScale", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("normalMap", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("normalMapType", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("normalScale", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("displacementMap", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("displacementScale", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("displacementBias", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("specularMap", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("alphaMap", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("envMap", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("combine", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("reflectivity", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("refractionRatio", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("wireframe", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("wireframeLinewidth", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("wireframeLinecap", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("wireframeLinejoin", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("flatShading", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("fog", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                // PUBLIC
                QUnit.test("isMeshPhongMaterial", function(assert) {
                    var object = new MeshPhongMaterial();
                    assert.ok(object.isMeshPhongMaterial, "MeshPhongMaterial.isMeshPhongMaterial should be true");
                });

                QUnit.todo("copy", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });
            });
        });
    }
}