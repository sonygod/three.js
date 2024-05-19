package three.test.unit.src.materials;

import three.materials.ShaderMaterial;
import three.materials.Material;

class ShaderMaterialTests {

    public function new() {}

    public static function main() {
        QUnit.module("Materials", () => {
            QUnit.module("ShaderMaterial", () => {
                // INHERITANCE
                QUnit.test("Extending", (assert:QUnitAssert) => {
                    var object = new ShaderMaterial();
                    assert.strictEqual(object instanceof Material, true, 'ShaderMaterial extends from Material');
                });

                // INSTANCING
                QUnit.test("Instancing", (assert:QUnitAssert) => {
                    var object = new ShaderMaterial();
                    assert.ok(object, 'Can instantiate a ShaderMaterial.');
                });

                // PROPERTIES
                QUnit.test("type", (assert:QUnitAssert) => {
                    var object = new ShaderMaterial();
                    assert.ok(object.type == 'ShaderMaterial', 'ShaderMaterial.type should be ShaderMaterial');
                });

                QUnit.todo("defines", (assert:QUnitAssert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("uniforms", (assert:QUnitAssert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("uniformsGroups", (assert:QUnitAssert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("vertexShader", (assert:QUnitAssert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("fragmentShader", (assert:QUnitAssert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("linewidth", (assert:QUnitAssert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("wireframe", (assert:QUnitAssert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("wireframeLinewidth", (assert:QUnitAssert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("fog", (assert:QUnitAssert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("lights", (assert:QUnitAssert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("clipping", (assert:QUnitAssert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("extensions", (assert:QUnitAssert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("defaultAttributeValues", (assert:QUnitAssert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("index0AttributeName", (assert:QUnitAssert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("uniformsNeedUpdate", (assert:QUnitAssert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("glslVersion", (assert:QUnitAssert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // PUBLIC
                QUnit.test("isShaderMaterial", (assert:QUnitAssert) => {
                    var object = new ShaderMaterial();
                    assert.ok(object.isShaderMaterial, 'ShaderMaterial.isShaderMaterial should be true');
                });

                QUnit.todo("copy", (assert:QUnitAssert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("toJSON", (assert:QUnitAssert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
            });
        });
    }
}