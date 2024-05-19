package three.js.test.unit.src.geometries;

import three.geom.TubeGeometry;
import three.extras.curves.LineCurve3;
import three.math.Vector3;
import three.core.BufferGeometry;

class TubeGeometryTests {
    static function main() {
        QUnit.module("Geometries", () => {
            QUnit.module("TubeGeometry", (hooks) => {
                var geometries:Array<TubeGeometry>;

                hooks.beforeEach(() => {
                    var path = new LineCurve3(new Vector3(0, 0, 0), new Vector3(0, 1, 0));
                    geometries = [new TubeGeometry(path)];
                });

                // INHERITANCE
                QUnit.test("Extending", (assert) => {
                    var object = new TubeGeometry();
                    assert.ok(object instanceof BufferGeometry, "TubeGeometry extends from BufferGeometry");
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) => {
                    var object = new TubeGeometry();
                    assert.ok(object != null, "Can instantiate a TubeGeometry.");
                });

                // PROPERTIES
                QUnit.test("type", (assert) => {
                    var object = new TubeGeometry();
                    assert.ok(object.type == "TubeGeometry", "TubeGeometry.type should be TubeGeometry");
                });

                // todo tests
                QUnit.todo("parameters", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("tangents", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("normals", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("binormals", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                // PUBLIC
                QUnit.todo("toJSON", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                // STATIC
                QUnit.todo("fromJSON", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                // OTHERS
                QUnit.todo("Standard geometry tests", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });
            });
        });
    }
}