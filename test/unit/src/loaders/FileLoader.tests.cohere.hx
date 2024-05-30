import js.QUnit;

import js.d.loaders.FileLoader;
import js.d.loaders.Loader;

class _Main {
    static function main() {
        var module = QUnit.module("Loaders");
        module.module("FileLoader", function() {
            QUnit.test("Extending", function(assert) {
                var object = new FileLoader();
                assert.strictEqual(Std.is(object, Loader), true, "FileLoader extends from Loader");
            });

            QUnit.test("Instancing", function(assert) {
                var object = new FileLoader();
                assert.ok(object, "Can instantiate a FileLoader.");
            });

            QUnit.todo("load", function(assert) {
                assert.ok(false, "everything's gonna be alright");
            });

            QUnit.todo("setResponseType", function(assert) {
                assert.ok(false, "everything's gonna be alright");
            });

            QUnit.todo("setMimeType", function(assert) {
                assert.ok(false, "everything's gonna be alright");
            });
        });
    }
}