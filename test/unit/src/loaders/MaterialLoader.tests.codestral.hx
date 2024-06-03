import three.loaders.MaterialLoader;
import three.loaders.Loader;
import qunit.QUnit;

class MaterialLoaderTests {
    public function new() {
        QUnit.module("Loaders", () -> {
            QUnit.module("MaterialLoader", () -> {
                // INHERITANCE
                QUnit.test("Extending", (assert) -> {
                    var object:MaterialLoader = new MaterialLoader();
                    assert.strictEqual(Std.is(object, Loader), true, "MaterialLoader extends from Loader");
                });

                // PROPERTIES
                QUnit.test("textures", (assert) -> {
                    var actual = new MaterialLoader().textures;
                    var expected:haxe.ds.StringMap<Dynamic> = new haxe.ds.StringMap();
                    assert.deepEqual(actual, expected, "MaterialLoader defines textures.");
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) -> {
                    var object:MaterialLoader = new MaterialLoader();
                    assert.ok(object, "Can instantiate a MaterialLoader.");
                });

                // PUBLIC
                QUnit.todo("load", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("parse", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("setTextures", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                // STATIC
                QUnit.todo("createMaterialFromType", (assert) -> {
                    // static createMaterialFromType(type)
                    assert.ok(false, "everything's gonna be alright");
                });
            });
        });
    }
}