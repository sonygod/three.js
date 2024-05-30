package three.unit.loaders;

import three.loaders.MaterialLoader;
import three.loaders.Loader;

class MaterialLoaderTests {
    public function new() {}

    public static function main() {
        // INHERITANCE
        Tester.test("Extending", function(assert) {
            var object = new MaterialLoader();
            assert.isTrue(object instanceof Loader, 'MaterialLoader extends from Loader');
        });

        // PROPERTIES
        Tester.test("textures", function(assert) {
            var actual = new MaterialLoader().textures;
            var expected = {};
            assert.deepEqual(actual, expected, 'MaterialLoader defines textures.');
        });

        // INSTANCING
        Tester.test("Instancing", function(assert) {
            var object = new MaterialLoader();
            assert.notNull(object, 'Can instantiate a MaterialLoader.');
        });

        // PUBLIC
        Tester.todo("load", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        Tester.todo("parse", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        Tester.todo("setTextures", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        // STATIC
        Tester.todo("createMaterialFromType", function(assert) {
            // static createMaterialFromType( type )
            assert.fail("everything's gonna be alright");
        });
    }
}