import js.QUnit;
import js.WebGL.Textures.DataTexture;
import js.WebGL.Textures.Texture;

class TestDataTexture {
    static function main() {
        QUnit.module('Textures', {
            beforeEach: function() {
                // ...
            },
            afterEach: function() {
                // ...
            }
        });

        QUnit.module('DataTexture', function() {
            // INHERITANCE
            QUnit.test('Extending', function(assert) {
                var object = new DataTexture();
                assert.strictEqual(
                    object instanceof Texture, true,
                    'DataTexture extends from Texture'
                );
            });

            // INSTANCING
            QUnit.test('Instancing', function(assert) {
                var object = new DataTexture();
                assert.ok(object, 'Can instantiate a DataTexture.');
            });

            // PROPERTIES
            QUnit.todo('image', function(assert) {
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
            QUnit.test('isDataTexture', function(assert) {
                var object = new DataTexture();
                assert.ok(
                    object.isDataTexture,
                    'DataTexture.isDataTexture should be true'
                );
            });
        });
    }
}

TestDataTexture.main();