package three.test.unit.src.geometries;

import three.geometries.CircleGeometry;
import three.core.BufferGeometry;
import three.test.utils.QUnitUtils;

class CircleGeometryTest {
    public function new() {}

    public static function main() {
        QUnit.module("Geometries", () => {
            QUnit.module("CircleGeometry", (hooks) => {
                var geometries:Array<CircleGeometry>;

                hooks.beforeEach(() => {
                    var parameters = {
                        radius: 10,
                        segments: 20,
                        thetaStart: 0.1,
                        thetaLength: 0.2
                    };

                    geometries = [
                        new CircleGeometry(),
                        new CircleGeometry(parameters.radius),
                        new CircleGeometry(parameters.radius, parameters.segments),
                        new CircleGeometry(parameters.radius, parameters.segments, parameters.thetaStart),
                        new CircleGeometry(parameters.radius, parameters.segments, parameters.thetaStart, parameters.thetaLength),
                    ];
                });

                QUnit.test("Extending", (assert) => {
                    var object = new CircleGeometry();
                    assert.ok(object instanceof BufferGeometry, "CircleGeometry extends from BufferGeometry");
                });

                QUnit.test("Instancing", (assert) => {
                    var object = new CircleGeometry();
                    assert.ok(object != null, "Can instantiate a CircleGeometry.");
                });

                QUnit.test("type", (assert) => {
                    var object = new CircleGeometry();
                    assert.ok(object.type == "CircleGeometry", "CircleGeometry.type should be CircleGeometry");
                });

                QUnit.todo("parameters", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("fromJSON", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.test("Standard geometry tests", (assert) => {
                    QUnitUtils.runStdGeometryTests(assert, geometries);
                });
            });
        });
    }
}