package three.test.unit.src.materials;

import three.materials.ShaderMaterial;
import three.materials.Material;

class ShaderMaterialTests {
  public function new() {}

  public static function main() {
    QUnit.module("Materials", () => {
      QUnit.module("ShaderMaterial", () => {
        // INHERITANCE
        QUnit.test("Extending", (assert) => {
          var object = new ShaderMaterial();
          assert.isTrue(object instanceof Material, 'ShaderMaterial extends from Material');
        });

        // INSTANCING
        QUnit.test("Instancing", (assert) => {
          var object = new ShaderMaterial();
          assertTrue(object != null, 'Can instantiate a ShaderMaterial.');
        });

        // PROPERTIES
        QUnit.test("type", (assert) => {
          var object = new ShaderMaterial();
          assertEquals(object.type, 'ShaderMaterial', 'ShaderMaterial.type should be ShaderMaterial');
        });

        QUnit.todo("defines", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("uniforms", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("uniformsGroups", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("vertexShader", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("fragmentShader", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("linewidth", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("wireframe", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("wireframeLinewidth", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("fog", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("lights", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("clipping", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("extensions", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("defaultAttributeValues", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("index0AttributeName", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("uniformsNeedUpdate", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("glslVersion", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        // PUBLIC
        QUnit.test("isShaderMaterial", (assert) => {
          var object = new ShaderMaterial();
          assertTrue(object.isShaderMaterial, 'ShaderMaterial.isShaderMaterial should be true');
        });

        QUnit.todo("copy", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("toJSON", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });
      });
    });
  }
}