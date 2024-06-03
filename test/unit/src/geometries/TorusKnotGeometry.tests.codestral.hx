import qunit.QUnit;
import three.geometries.TorusKnotGeometry;
import three.core.BufferGeometry;
import utils.QUnitUtils;

class TorusKnotGeometryTests {
    public function new() {
        QUnit.module("Geometries", () -> {
            QUnit.module("TorusKnotGeometry", (hooks) -> {
                var geometries:Array<TorusKnotGeometry> = [];

                hooks.beforeEach(() -> {
                    var parameters = {
                        radius: 10,
                        tube: 20,
                        tubularSegments: 30,
                        radialSegments: 10,
                        p: 3,
                        q: 2
                    };

                    geometries = [
                        new TorusKnotGeometry(),
                        new TorusKnotGeometry(parameters.radius),
                        new TorusKnotGeometry(parameters.radius, parameters.tube),
                        new TorusKnotGeometry(parameters.radius, parameters.tube, parameters.tubularSegments),
                        new TorusKnotGeometry(parameters.radius, parameters.tube, parameters.tubularSegments, parameters.radialSegments),
                        new TorusKnotGeometry(parameters.radius, parameters.tube, parameters.tubularSegments, parameters.radialSegments, parameters.p, parameters.q),
                    ];
                });

                QUnit.test("Extending", (assert) -> {
                    var object = new TorusKnotGeometry();
                    assert.strictEqual(
                        Std.is(object, BufferGeometry), true,
                        'TorusKnotGeometry extends from BufferGeometry'
                    );
                });

                QUnit.test("Instancing", (assert) -> {
                    var object = new TorusKnotGeometry();
                    assert.ok(object != null, 'Can instantiate a TorusKnotGeometry.');
                });

                QUnit.test("type", (assert) -> {
                    var object = new TorusKnotGeometry();
                    assert.ok(
                        object.type == 'TorusKnotGeometry',
                        'TorusKnotGeometry.type should be TorusKnotGeometry'
                    );
                });

                QUnit.todo("parameters", (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("fromJSON", (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.test("Standard geometry tests", (assert) -> {
                    QUnitUtils.runStdGeometryTests(assert, geometries);
                });
            });
        });
    }
}