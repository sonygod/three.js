package three.js.test.unit.src.geometries;

import three.js.src.geometries.BoxGeometry;
import three.js.src.core.BufferGeometry;
import three.js.test.unit.utils.QUnitUtils;

class BoxGeometryTest {

    public function new() {}

    public static function main() {
        QUnit.module("Geometries", () -> {
            QUnit.module("BoxGeometry", (hooks) -> {
                var geometries:Array<BufferGeometry> = null;
                hooks.beforeEach(() -> {
                    var parameters = {
                        width: 10,
                        height: 20,
                        depth: 30,
                        widthSegments: 2,
                        heightSegments: 3,
                        depthSegments: 4
                    };
                    geometries = [
                        new BoxGeometry(),
                        new BoxGeometry(parameters.width, parameters.height, parameters.depth),
                        new BoxGeometry(parameters.width, parameters.height, parameters.depth, parameters.widthSegments, parameters.heightSegments, parameters.depthSegments)
                    ];
                });

                // INHERITANCE
                QUnit.test("Extending", (assert) -> {
                    var object = new BoxGeometry();
                    assert.isTrue(object instanceof BufferGeometry, "BoxGeometry extends from BufferGeometry");
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) -> {
                    var object = new BoxGeometry();
                    assert.ok(object, "Can instantiate a BoxGeometry.");
                });

                // PROPERTIES
                QUnit.test("type", (assert) -> {
                    var object = new BoxGeometry();
                    assert.equal(object.type, "BoxGeometry", "BoxGeometry.type should be BoxGeometry");
                });

                QUnit.todo("parameters", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                // STATIC
                QUnit.todo("fromJSON", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                // OTHERS
                QUnit.test("Standard geometry tests", (assert) -> {
                    QUnitUtils.runStdGeometryTests(assert, geometries);
                });
            });
        });
    }
}