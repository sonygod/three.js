import js.Browser.document;
import js.html.QUnit;
import core.Object3D;
import objects.Line;
import objects.LineLoop;

class LineLoopTest {
    public function new() {
        QUnit.module("Objects", () -> {
            QUnit.module("LineLoop", () -> {

                // INHERITANCE
                QUnit.test("Extending", assert -> {
                    var lineLoop:LineLoop = new LineLoop();

                    assert.strictEqual(js.Boot.isOfType(lineLoop, Object3D), true, 'LineLoop extends from Object3D');
                    assert.strictEqual(js.Boot.isOfType(lineLoop, Line), true, 'LineLoop extends from Line');
                });

                // INSTANCING
                QUnit.test("Instancing", assert -> {
                    var object:LineLoop = new LineLoop();
                    assert.ok(object != null, 'Can instantiate a LineLoop.');
                });

                // PROPERTIES
                QUnit.test("type", assert -> {
                    var object:LineLoop = new LineLoop();
                    assert.ok(object.type == "LineLoop", 'LineLoop.type should be LineLoop');
                });

                // PUBLIC
                QUnit.test("isLineLoop", assert -> {
                    var object:LineLoop = new LineLoop();
                    assert.ok(object.isLineLoop, 'LineLoop.isLineLoop should be true');
                });
            });
        });
    }
}

var test = new LineLoopTest();