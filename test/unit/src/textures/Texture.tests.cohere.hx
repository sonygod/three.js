package;

import js.QUnit;
import openfl.display.BitmapData;
import openfl.display.Texture;
import openfl.events.EventDispatcher;

class TextureTest {
    public static function main() {
        QUnit.module('Textures', {
            setup: function() {
                // ...
            },
            teardown: function() {
                // ...
            }
        });

        QUnit.module('Texture', function() {
            QUnit.test('Extending', function(assert) {
                var object = new Texture(null, null, null, false, 0, 0, 0, 0, false, false, false);
                assert.strictEqual(object instanceof EventDispatcher, true, 'Texture extends from EventDispatcher');
            });

            QUnit.test('Instancing', function(assert) {
                // no params
                var object = new Texture(null, null, null, false, 0, 0, 0, 0, false, false, false);
                assert.ok(object, 'Can instantiate a Texture.');
            });

            QUnit.test('isTexture', function(assert) {
                var object = new Texture(null, null, null, false, 0, 0, 0, 0, false, false, false);
                assert.ok(object.isTexture, 'Texture.isTexture should be true');
            });

            QUnit.test('dispose', function(assert) {
                assert.expect(0);
                var object = new Texture(null, null, null, false, 0, 0, 0, 0, false, false, false);
                object.dispose();
            });
        });
    }
}