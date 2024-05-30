import js.QUnit;
import js.THREE.loaders.ImageBitmapLoader;
import js.THREE.loaders.Loader;
import js.THREE.utils.consoleWrapper.CONSOLE_LEVEL;

class _Main {
    static function main() {
        QUnit.module('Loaders', {
            setup: function() {
                // called before each test
            },
            teardown: function() {
                // called after each test
            }
        }, function() {
            QUnit.module('ImageBitmapLoader', {
                setup: function() {
                    // called before each test
                },
                teardown: function() {
                    // called after each test
                }
            }, function() {
                // INHERITANCE
                QUnit.test('Extending', function(assert) {
                    // surpress the following console message when testing
                    // THREE.ImageBitmapLoader: createImageBitmap() not supported.

                    var console_level = Console.get_level();
                    Console.set_level(CONSOLE_LEVEL.OFF);
                    var object = new ImageBitmapLoader();
                    Console.set_level(console_level);

                    assert.strictEqual(
                        Std.is(object, Loader), true,
                        'ImageBitmapLoader extends from Loader'
                    );
                });

                // INSTANCING
                QUnit.test('Instancing', function(assert) {
                    // surpress the following console message when testing
                    // THREE.ImageBitmapLoader: createImageBitmap() not supported.

                    var console_level = Console.get_level();
                    Console.set_level(CONSOLE_LEVEL.OFF);
                    var object = new ImageBitmapLoader();
                    Console.set_level(console_level);

                    assert.ok(object, 'Can instantiate an ImageBitmapLoader.');
                });

                // PROPERTIES
                QUnit.test('options', function(assert) {
                    // surpress the following console message when testing in node
                    // THREE.ImageBitmapLoader: createImageBitmap() not supported.

                    var console_level = Console.get_level();
                    Console.set_level(CONSOLE_LEVEL.OFF);
                    var actual = new ImageBitmapLoader().options;
                    Console.set_level(console_level);

                    var expected = { premultiplyAlpha: 'none' };
                    assert.deepEqual(actual, expected, 'ImageBitmapLoader defines options.');
                });

                // PUBLIC
                QUnit.test('isImageBitmapLoader', function(assert) {
                    // surpress the following console message when testing in node
                    // THREE.ImageBitmapLoader: createImageBitmap() not supported.

                    var console_level = Console.get_level();
                    Console.set_level(CONSOLE_LEVEL.OFF);
                    var object = new ImageBitmapLoader();
                    Console.set_level(console_level);

                    assert.ok(
                        object.isImageBitmapLoader,
                        'ImageBitmapLoader.isImageBitmapLoader should be true'
                    );
                });

                QUnit.todo('setOptions', function(assert) {
                    // setOptions( options )
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('load', function(assert) {
                    // load( url, onLoad, onProgress, onError )
                    assert.ok(false, 'everything\'s gonna be alright');
                });
            });
        });
    }
}