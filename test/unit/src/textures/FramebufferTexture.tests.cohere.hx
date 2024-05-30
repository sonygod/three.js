import js.QUnit;
import js.webgl.FramebufferTexture;
import js.webgl.Texture;

class TestFramebufferTexture {
    static function main() {
        QUnit.module('Textures', {
            beforeEach: function() {},
            afterEach: function() {}
        });

        QUnit.module('FramebufferTexture', {
            beforeEach: function() {},
            afterEach: function() {}
        });

        // INHERITANCE
        QUnit.test('Extending', function(assert) {
            var object = new FramebufferTexture();
            assert.strictEqual(
                object instanceof Texture,
                true,
                'FramebufferTexture extends from Texture'
            );
        });

        // INSTANCING
        QUnit.test('Instancing', function(assert) {
            var object = new FramebufferTexture();
            assert.ok(object, 'Can instantiate a FramebufferTexture.');
        });

        // PROPERTIES
        QUnit.todo('format', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('magFilter', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('minFilter', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('generateMipmaps', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('needsUpdate', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        // PUBLIC
        QUnit.test('isFramebufferTexture', function(assert) {
            var object = new FramebufferTexture();
            assert.ok(
                object.isFramebufferTexture,
                'FramebufferTexture.isFramebufferTexture should be true'
            );
        });
    }
}

TestFramebufferTexture.main();