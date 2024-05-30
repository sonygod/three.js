import js.QUnit;

import openfl.display.DataArrayTexture;
import openfl.display.Texture;

class TestDataArrayTexture {
    public static function main() {
        QUnit.module('Textures', {
            setup: function() {
                // ...
            },
            teardown: function() {
                // ...
            }
        });

        QUnit.module('DataArrayTexture', {
            setup: function() {
                // ...
            },
            teardown: function() {
                // ...
            }
        });

        // INHERITANCE
        QUnit.test('Extending', function(assert) {
            var object = new DataArrayTexture();
            assert.strictEqual(object instanceof Texture, true, 'DataArrayTexture extends from Texture');
        });

        // INSTANCING
        QUnit.test('Instancing', function(assert) {
            var object = new DataArrayTexture();
            assert.ok(object, 'Can instantiate a DataArrayTexture.');
        });

        // PROPERTIES
        QUnit.todo('image', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('magFilter', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('minFilter', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('wrapR', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('generateMipmaps', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('flipY', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('unpackAlignment', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        // PUBLIC
        QUnit.test('isDataArrayTexture', function(assert) {
            var object = new DataArrayTexture();
            assert.ok(object.isDataArrayTexture, 'DataArrayTexture.isDataArrayTexture should be true');
        });
    }
}

TestDataArrayTexture.main();