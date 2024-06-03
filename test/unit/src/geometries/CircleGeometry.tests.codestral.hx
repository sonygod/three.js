import js.Browser.document;
import js.QUnit;
import three.geometries.CircleGeometry;
import three.core.BufferGeometry;
import utils.QUnitUtils;

class CircleGeometryTests {
    public function new() {
        QUnit.module("Geometries", () -> {
            QUnit.module("CircleGeometry", (hooks: QUnit.Hooks) -> {
                var geometries: Array<CircleGeometry> = [];

                hooks.beforeEach(function() {
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

                QUnit.test("Extending", (assert: QUnit.Assert) -> {
                    var object = new CircleGeometry();
                    assert.strictEqual(Std.is(object, CircleGeometry), true, "CircleGeometry extends from BufferGeometry");
                });

                QUnit.test("Instancing", (assert: QUnit.Assert) -> {
                    var object = new CircleGeometry();
                    assert.ok(object, "Can instantiate a CircleGeometry.");
                });

                QUnit.test("type", (assert: QUnit.Assert) -> {
                    var object = new CircleGeometry();
                    assert.ok(object.type == "CircleGeometry", "CircleGeometry.type should be CircleGeometry");
                });

                QUnit.todo("parameters", (assert: QUnit.Assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("fromJSON", (assert: QUnit.Assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.test("Standard geometry tests", (assert: QUnit.Assert) -> {
                    QUnitUtils.runStdGeometryTests(assert, geometries);
                });
            });
        });
    }
}