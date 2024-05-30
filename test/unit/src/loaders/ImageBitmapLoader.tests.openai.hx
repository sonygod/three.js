package three.js.test.unit.src.loaders;

import three.js.loaders.ImageBitmapLoader;
import three.js.loaders.Loader;
import three.utils.ConsoleWrapper;

class ImageBitmapLoaderTests {
    public function new() {}

    public static function main() {
        QUnit.module("Loaders", () -> {
            QUnit.module("ImageBitmapLoader", () -> {
                // INHERITANCE
                QUnit.test("Extending", (assert) -> {
                    ConsoleWrapper.level = ConsoleWrapper_Level.OFF;
                    var object = new ImageBitmapLoader();
                    ConsoleWrapper.level = ConsoleWrapper_Level.DEFAULT;
                    assert.ok(object instanceof Loader, "ImageBitmapLoader extends from Loader");
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) -> {
                    ConsoleWrapper.level = ConsoleWrapper_Level.OFF;
                    var object = new ImageBitmapLoader();
                    ConsoleWrapper.level = ConsoleWrapper_Level.DEFAULT;
                    assert.ok(object, "Can instantiate an ImageBitmapLoader.");
                });

                // PROPERTIES
                QUnit.test("options", (assert) -> {
                    ConsoleWrapper.level = ConsoleWrapper_Level.OFF;
                    var actual = new ImageBitmapLoader().options;
                    ConsoleWrapper.level = ConsoleWrapper_Level.DEFAULT;
                    var expected = { premultiplyAlpha: 'none' };
                    assert.deepEqual(actual, expected, "ImageBitmapLoader defines options.");
                });

                // PUBLIC
                QUnit.test("isImageBitmapLoader", (assert) -> {
                    ConsoleWrapper.level = ConsoleWrapper_Level.OFF;
                    var object = new ImageBitmapLoader();
                    ConsoleWrapper.level = ConsoleWrapper_Level.DEFAULT;
                    assert.ok(object.isImageBitmapLoader, "ImageBitmapLoader.isImageBitmapLoader should be true");
                });

                QUnit.todo("setOptions", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("load", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });
            });
        });
    }
}