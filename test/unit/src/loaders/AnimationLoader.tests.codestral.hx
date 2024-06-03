import qunit.QUnit;
import three.loaders.AnimationLoader;
import three.loaders.Loader;

class AnimationLoaderTests {
    public function new() {
        QUnit.module("Loaders", () -> {
            QUnit.module("AnimationLoader", () -> {
                QUnit.test("Extending", (assert) -> {
                    var object:AnimationLoader = new AnimationLoader();
                    assert.strictEqual(Std.is(object, Loader), true, "AnimationLoader extends from Loader");
                });

                QUnit.test("Instancing", (assert) -> {
                    var object:AnimationLoader = new AnimationLoader();
                    assert.notNull(object, "Can instantiate an AnimationLoader.");
                });

                QUnit.todo("load", (assert) -> {
                    assert.fail("Not implemented");
                });

                QUnit.todo("parse", (assert) -> {
                    assert.fail("Not implemented");
                });
            });
        });
    }
}