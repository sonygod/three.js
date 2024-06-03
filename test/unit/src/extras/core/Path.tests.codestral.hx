import js.Browser.document;
import js.Browser.window;
import js.qunit.QUnit;
import three.extras.core.Path;
import three.extras.core.CurvePath;

class PathTests {
    public function new() {
        QUnit.module("Extras", () -> {
            QUnit.module("Core", () -> {
                QUnit.module("Path", () -> {
                    QUnit.test("Extending", assert -> {
                        var object:Path = new Path();
                        assert.strictEqual(Std.is(object, CurvePath), true, 'Path extends from CurvePath');
                    });

                    QUnit.test("Instancing", assert -> {
                        var object:Path = new Path();
                        assert.notEqual(object, null, 'Can instantiate a Path.');
                    });

                    QUnit.test("type", assert -> {
                        var object:Path = new Path();
                        assert.equal(object.type, 'Path', 'Path.type should be Path');
                    });

                    // Add other test cases here as needed
                });
            });
        });
    }
}