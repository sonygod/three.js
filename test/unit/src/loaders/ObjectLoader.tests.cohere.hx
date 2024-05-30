import js.QUnit;

import openfl.display.DisplayObject;
import openfl.display.Loader;

import openfl.loaders.ObjectLoader;

class TestObjectLoader {
    static function extending() {
        var object = new ObjectLoader();
        QUnit.strictEqual(object instanceof Loader, true, "ObjectLoader extends from Loader");
    }

    static function instancing() {
        var object = new ObjectLoader();
        QUnit.ok(object, "Can instantiate an ObjectLoader.");
    }

    static function load() {
        // TODO: Implement test
    }

    static function loadAsync() {
        // TODO: Implement test for async function
    }

    static function parse() {
        // TODO: Implement test
    }

    static function parseAsync() {
        // TODO: Implement test for async function
    }

    static function parseShapes() {
        // TODO: Implement test
    }

    static function parseSkeletons() {
        // TODO: Implement test
    }

    static function parseGeometries() {
        // TODO: Implement test
    }

    static function parseMaterials() {
        // TODO: Implement test
    }

    static function parseAnimations() {
        // TODO: Implement test
    }

    static function parseImages() {
        // TODO: Implement test
    }

    static function parseImagesAsync() {
        // TODO: Implement test for async function
    }

    static function parseTextures() {
        // TODO: Implement test
    }

    static function parseObject() {
        // TODO: Implement test
    }

    static function bindSkeletons() {
        // TODO: Implement test
    }

    public static function main() {
        QUnit.module("Loaders", setup => {
            QUnit.module("ObjectLoader", () -> {
                QUnit.test("Extending", extending);
                QUnit.test("Instancing", instancing);
                QUnit.todo("load", load);
                QUnit.todo("loadAsync", loadAsync);
                QUnit.todo("parse", parse);
                QUnit.todo("parseAsync", parseAsync);
                QUnit.todo("parseShapes", parseShapes);
                QUnit.todo("parseSkeletons", parseSkeletons);
                QUnit.todo("parseGeometries", parseGeometries);
                QUnit.todo("parseMaterials", parseMaterials);
                QUnit.todo("parseAnimations", parseAnimations);
                QUnit.todo("parseImages", parseImages);
                QUnit.todo("parseImagesAsync", parseImagesAsync);
                QUnit.todo("parseTextures", parseTextures);
                QUnit.todo("parseObject", parseObject);
                QUnit.todo("bindSkeletons", bindSkeletons);
            });
        });
    }
}

TestObjectLoader.main();