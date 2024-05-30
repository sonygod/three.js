import js.QUnit;
import js.CompressedTexture;
import js.Texture;

class TestCompressedTexture {
    static function main() {
        QUnit.module('Textures', {
            beforeEach: function() {},
            afterEach: function() {}
        });

        QUnit.module('CompressedTexture', {
            beforeEach: function() {},
            afterEach: function() {}
        });

        // INHERITANCE
        QUnit.test('Extending', function(assert) {
            var object = new CompressedTexture();
            assert.strictEqual(Std.is(object, Texture), true, 'CompressedTexture extends from Texture');
        });

        // INSTANCING
        QUnit.test('Instancing', function(assert) {
            var object = new CompressedTexture();
            assert.ok(object, 'Can instantiate a CompressedTexture.');
        });

        // PROPERTIES
        QUnit.todo('image', function(assert) {
            // { width: width, height: height }
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('mipmaps', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('flipY', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('generateMipmaps', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        // PUBLIC
        QUnit.test('isCompressedTexture', function(assert) {
            var object = new CompressedTexture();
            assert.ok(object.isCompressedTexture, 'CompressedTexture.isCompressedTexture should be true');
        });
    }
}