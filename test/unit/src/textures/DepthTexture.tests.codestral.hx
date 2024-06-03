import qunit.QUnit;
import three.src.textures.DepthTexture;
import three.src.textures.Texture;

class DepthTextureTests {
    public static function main() {
        QUnit.module("Textures", () -> {
            QUnit.module("DepthTexture", () -> {
                QUnit.test("Extending", ( assert ) -> {
                    var object: DepthTexture = new DepthTexture();
                    assert.strictEqual(Std.is(object, Texture), true, 'DepthTexture extends from Texture');
                });

                QUnit.test("Instancing", ( assert ) -> {
                    var object: DepthTexture = new DepthTexture();
                    assert.isNotNull(object, 'Can instantiate a DepthTexture.');
                });

                QUnit.todo("image", ( assert ) -> {
                    assert.isFalse(true, 'everything\'s gonna be alright');
                });

                QUnit.todo("magFilter", ( assert ) -> {
                    assert.isFalse(true, 'everything\'s gonna be alright');
                });

                QUnit.todo("minFilter", ( assert ) -> {
                    assert.isFalse(true, 'everything\'s gonna be alright');
                });

                QUnit.todo("flipY", ( assert ) -> {
                    assert.isFalse(true, 'everything\'s gonna be alright');
                });

                QUnit.todo("generateMipmaps", ( assert ) -> {
                    assert.isFalse(true, 'everything\'s gonna be alright');
                });

                QUnit.test("isDepthTexture", ( assert ) -> {
                    var object: DepthTexture = new DepthTexture();
                    assert.isTrue(object.isDepthTexture, 'DepthTexture.isDepthTexture should be true');
                });
            });
        });
    }
}