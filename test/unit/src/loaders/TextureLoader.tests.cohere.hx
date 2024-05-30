import js.QUnit;
import js.jquery.loaders.TextureLoader;
import js.jquery.loaders.Loader;

class TextureLoaderTest {
    static function main() {
        QUnit.module('Loaders', {
            setup: function() {}, teardown: function() {}
        });

        QUnit.module('TextureLoader', {
            setup: function() {}, teardown: function() {}
        });

        // INHERITANCE
        QUnit.test('Extending', function(assert) {
            var object = new TextureLoader();
            assert.strictEqual(Std.is(object, Loader), true, 'TextureLoader extends from Loader');
        });

        // INSTANCING
        QUnit.test('Instancing', function(assert) {
            var object = new TextureLoader();
            assert.ok(object, 'Can instantiate a TextureLoader.');
        });

        // PUBLIC
        QUnit.todo('load', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });
    }
}