package three.test.unit.src.textures;

import haxe.unit.TestCase;
import three.textures.FramebufferTexture;
import three.textures.Texture;

class FramebufferTextureTests {

    public function new() {}

    public function testFramebufferTexture() {
        // INHERITANCE
        testCase(new TestCase(), "Extending", function(assert) {
            var object = new FramebufferTexture();
            assert.isTrue(object instanceof Texture, 'FramebufferTexture extends from Texture');
        });

        // INSTANCING
        testCase(new TestCase(), "Instancing", function(assert) {
            var object = new FramebufferTexture();
            assert.isTrue(object != null, 'Can instantiate a FramebufferTexture.');
        });

        // PROPERTIES
        testCase(new TestCase(), "format", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        testCase(new TestCase(), "magFilter", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        testCase(new TestCase(), "minFilter", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        testCase(new TestCase(), "generateMipmaps", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        testCase(new TestCase(), "needsUpdate", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        // PUBLIC
        testCase(new TestCase(), "isFramebufferTexture", function(assert) {
            var object = new FramebufferTexture();
            assert.isTrue(object.isFramebufferTexture, 'FramebufferTexture.isFramebufferTexture should be true');
        });
    }
}