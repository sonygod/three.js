package three.tests.unit.src.textures;

import three.textures.Texture;
import three.core.EventDispatcher;

class TextureTests {

    public function new() {}

    public static function main() {
        QUnit.module("Textures", () -> {

            QUnit.module("Texture", () -> {

                // INHERITANCE
                QUnit.test("Extending", (assert:QUnitAssert) -> {
                    var object = new Texture();
                    assert.ok(object instanceof EventDispatcher, 'Texture extends from EventDispatcher');
                });

                // INSTANCING
                QUnit.test("Instancing", (assert:QUnitAssert) -> {
                    // no params
                    var object = new Texture();
                    assert.ok(object != null, 'Can instantiate a Texture.');
                });

                // PROPERTIES
                QUnit.todo("image", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("id", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("uuid", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("name", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("source", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("mipmaps", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("mapping", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("wrapS", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("wrapT", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("magFilter", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("minFilter", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("anisotropy", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("format", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("internalFormat", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("type", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("offset", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("repeat", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("center", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("rotation", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("matrixAutoUpdate", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("matrix", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("generateMipmaps", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("premultiplyAlpha", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("flipY", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("unpackAlignment", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("colorSpace", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("userData", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("version", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("onUpdate", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("needsPMREMUpdate", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // PUBLIC
                QUnit.test("isTexture", (assert:QUnitAssert) -> {
                    var object = new Texture();
                    assert.ok(object.isTexture, 'Texture.isTexture should be true');
                });

                QUnit.todo("updateMatrix", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("clone", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("copy", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("toJSON", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.test("dispose", (assert:QUnitAssert) -> {
                    assert.expect(0);
                    var object = new Texture();
                    object.dispose();
                });

                QUnit.todo("transformUv", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
            });
        });
    }
}