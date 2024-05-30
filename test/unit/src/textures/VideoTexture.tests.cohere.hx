import js.QUnit;
import js.web.dom.HTMLElement;

import openfl.display.VideoTexture;
import openfl.textures.Texture;

class TestVideoTexture {
    public static function main() {
        QUnit.module('Textures', {
            setup: function() {},
            teardown: function() {}
        });

        QUnit.module('VideoTexture', {
            setup: function() {},
            teardown: function() {}
        });

        // INHERITANCE
        QUnit.test('Extending', function(assert) {
            var videoDocumentElement = new HTMLElement();
            var object = new VideoTexture(videoDocumentElement);
            assert.strictEqual(
                Std.is(object, Texture),
                true,
                'VideoTexture extends from Texture'
            );
        });

        // INSTANCING
        QUnit.test('Instancing', function(assert) {
            var videoDocumentElement = new HTMLElement();
            var object = new VideoTexture(videoDocumentElement);
            assert.ok(object, 'Can instantiate a VideoTexture.');
        });

        // PROPERTIES
        QUnit.todo('minFilter', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('magFilter', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('generateMipmaps', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        // PUBLIC STUFF
        QUnit.test('isVideoTexture', function(assert) {
            var videoDocumentElement = new HTMLElement();
            var object = new VideoTexture(videoDocumentElement);
            assert.ok(
                object.isVideoTexture,
                'VideoTexture.isVideoTexture should be true'
            );
        });

        QUnit.todo('clone', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('update', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });
    }
}