import js.Browser.document;
import js.QUnit;
import three.js.geometries.TorusGeometry;
import three.js.core.BufferGeometry;
import three.js.utils.QUnitUtils.runStdGeometryTests;

class TorusGeometryTests {
    public function new() {
        QUnit.module("Geometries", () -> {
            QUnit.module("TorusGeometry", (hooks) -> {
                var geometries:Array<TorusGeometry> = null;

                hooks.beforeEach(() -> {
                    var parameters = {
                        radius: 10,
                        tube: 20,
                        radialSegments: 30,
                        tubularSegments: 10,
                        arc: 2.0,
                    };

                    geometries = [
                        new TorusGeometry(),
                        new TorusGeometry(parameters.radius),
                        new TorusGeometry(parameters.radius, parameters.tube),
                        new TorusGeometry(parameters.radius, parameters.tube, parameters.radialSegments),
                        new TorusGeometry(parameters.radius, parameters.tube, parameters.radialSegments, parameters.tubularSegments),
                        new TorusGeometry(parameters.radius, parameters.tube, parameters.radialSegments, parameters.tubularSegments, parameters.arc),
                    ];
                });

                QUnit.test("Extending", (assert) -> {
                    var object = new TorusGeometry();
                    assert.strictEqual(Std.is(object, BufferGeometry), true, 'TorusGeometry extends from BufferGeometry');
                });

                QUnit.test("Instancing", (assert) -> {
                    var object = new TorusGeometry();
                    assert.ok(object, 'Can instantiate a TorusGeometry.');
                });

                QUnit.test("type", (assert) -> {
                    var object = new TorusGeometry();
                    assert.ok(object.type == 'TorusGeometry', 'TorusGeometry.type should be TorusGeometry');
                });

                QUnit.todo("parameters", (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("fromJSON", (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.test("Standard geometry tests", (assert) -> {
                    runStdGeometryTests(assert, geometries);
                });
            });
        });
    }
}