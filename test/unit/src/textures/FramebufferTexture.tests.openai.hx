package three.test.unit.src.textures;

import three.textures.FramebufferTexture;
import three.textures.Texture;

class FramebufferTextureTests {
    public function new() {}

    public static function main() {
        // INHERITANCE
        utest.Test.createTest("Extending", function(assert) {
            var object = new FramebufferTexture();
            assert.isTrue(object instanceof Texture, 'FramebufferTexture extends from Texture');
        });

        // INSTANCING
        utest.Test.createTest("Instancing", function(assert) {
            var object = new FramebufferTexture();
            assert.notNull(object, 'Can instantiate a FramebufferTexture.');
        });

        // PROPERTIES
        utest.Test.createTest("format (TODO)", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        utest.Test.createTest("magFilter (TODO)", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        utest.Test.createTest("minFilter (TODO)", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        utest.Test.createTest("generateMipmaps (TODO)", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        utest.Test.createTest("needsUpdate (TODO)", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        // PUBLIC
        utest.Test.createTest("isFramebufferTexture", function(assert) {
            var object = new FramebufferTexture();
            assert.isTrue(object.isFramebufferTexture, 'FramebufferTexture.isFramebufferTexture should be true');
        });
    }
}