import js.QUnit;
import js.Data3DTexture;
import js.Texture;

class _Main {
    static function main() {
        QUnit.module('Textures', {
            setup: function() {},
            teardown: function() {}
        });

        QUnit.module('Data3DTexture', {
            setup: function() {},
            teardown: function() {}
        });

        // INHERITANCE
        QUnit.test('Extending', function(assert) {
            var object = new Data3DTexture();
            assert.strictEqual(object instanceof Texture, true, 'Data3DTexture extends from Texture');
        });

        // INSTANCING
        QUnit.test('Instancing', function(assert) {
            var object = new Data3DTexture();
            assert.ok(object, 'Can instantiate a Data3DTexture.');
        });

        // PROPERTIES
        QUnit.todo('image', function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo('magFilter', function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo('minFilter', function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo('wrapR', function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo('generateMipmaps', function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo('flipY', function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo('unpackAlignment', function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        // PUBLIC
        QUnit.test('isData3DTexture', function(assert) {
            var object = new Data3DTexture();
            assert.ok(object.isData3DTexture, 'Data3DTexture.isData3DTexture should be true');
        });
    }
}