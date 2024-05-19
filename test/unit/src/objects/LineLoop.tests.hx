package three.test.unit.src.objects;

import three.core.Object3D;
import three.objects.Line;
import three.objects.LineLoop;

class LineLoopTests {
    public function new() {}

    public static function main() {
        QUnit.module("Objects", () => {
            QUnit.module("LineLoop", () => {
                // INHERITANCE
                QUnit.test("Extending", (assert) => {
                    var lineLoop = new LineLoop();
                    assert.ok(lineLoop instanceof Object3D, "LineLoop extends from Object3D");
                    assert.ok(lineLoop instanceof Line, "LineLoop extends from Line");
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) => {
                    var object = new LineLoop();
                    assert.ok(object != null, "Can instantiate a LineLoop.");
                });

                // PROPERTIES
                QUnit.test("type", (assert) => {
                    var object = new LineLoop();
                    assert.ok(object.type == "LineLoop", "LineLoop.type should be LineLoop");
                });

                // PUBLIC
                QUnit.test("isLineLoop", (assert) => {
                    var object = new LineLoop();
                    assert.ok(object.isLineLoop, "LineLoop.isLineLoop should be true");
                });
            });
        });
    }
}