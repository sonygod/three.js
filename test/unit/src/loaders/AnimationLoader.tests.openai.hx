package three.loaders;

import utest.Runner;
import utest.ui.Report;
import three.loaders.AnimationLoader;
import three.loaders.Loader;

class AnimationLoaderTest {
    public static function addTests(runner:Runner) {
        runner.setDescription("Loaders");

        runner.addTest("AnimationLoader", {
            beforeEach : function() {
                // setup
            },

            "Extending" : function(assert) {
                var object = new AnimationLoader();
                assert.isTrue(object instanceof Loader, "AnimationLoader extends from Loader");
            },

            "Instancing" : function(assert) {
                var object = new AnimationLoader();
                assert.isOk(object, "Can instantiate an AnimationLoader.");
            },

            "load" : function(assert) {
                // todo
                assert.isOk(false, "everything's gonna be alright");
            },

            "parse" : function(assert) {
                // todo
                assert.isOk(false, "everything's gonna be alright");
            }
        });
    }

    public static function main() {
        var runner = new Runner();
        addTests(runner);
        Report.create(runner);
        runner.run();
    }
}