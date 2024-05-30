package three.helpers;

import three.helpers.ArrowHelper;
import three.core.Object3D;
import utest.Runner;
import utest.ui.Report;

class ArrowHelperTest {
    public static function addTests runner:Runner) {
        runner.describe("Helpers", () => {
            runner.describe("ArrowHelper", () => {
                // INHERITANCE
                runner.test("Extending", () => {
                    var object = new ArrowHelper();
                    Assert.isTrue(object instanceof Object3D, 'ArrowHelper extends from Object3D');
                });

                // INSTANCING
                runner.test("Instancing", () => {
                    var object = new ArrowHelper();
                    Assert.notNull(object, 'Can instantiate an ArrowHelper.');
                });

                // PROPERTIES
                runner.test("type", () => {
                    var object = new ArrowHelper();
                    Assert.equals(object.type, 'ArrowHelper', 'ArrowHelper.type should be ArrowHelper');
                });

                // TODOs
                runner.todo("position", () => {
                    Assert.fail("not implemented");
                });

                runner.todo("line", () => {
                    Assert.fail("not implemented");
                });

                runner.todo("cone", () => {
                    Assert.fail("not implemented");
                });

                // PUBLIC
                runner.todo("setDirection", () => {
                    Assert.fail("not implemented");
                });

                runner.todo("setLength", () => {
                    Assert.fail("not implemented");
                });

                runner.todo("setColor", () => {
                    Assert.fail("not implemented");
                });

                runner.todo("copy", () => {
                    Assert.fail("not implemented");
                });

                runner.test("dispose", () => {
                    var object = new ArrowHelper();
                    object.dispose();
                });
            });
        });
    }

    public static function main() {
        var runner = new Runner();
        addTests(runner);
        Report.create(runner);
        runner.run();
    }
}