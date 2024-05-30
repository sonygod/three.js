import js.QUnit.*;
import js.QUnit.QUnitModule;

import openfl.textures.Source;

class TestSuite {
    public static function main() {
        default module(typeof __filename, function() {
            module("Source", function() {
                // INSTANCING
                test("Instancing", function() {
                    var object = new Source();
                    ok(object != null, "Can instantiate a Source.");
                });

                // PROPERTIES
                todo("data", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                todo("needsUpdate", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                todo("uuid", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                todo("version", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                // PUBLIC
                test("isSource", function() {
                    var object = new Source();
                    ok(object.isSource, "Source.isSource should be true");
                });

                todo("toJSON", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });
            });
        });
    }
}