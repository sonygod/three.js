package three.test.unit.src.geometries;

import three.geometries.PlaneGeometry;
import three.core.BufferGeometry;
import three.utils.QUnitUtils;

class PlaneGeometryTests {
    public function new() {}

    public static function main():Void {
        QUnit.module("Geometries", () => {
            QUnit.module("PlaneGeometry", (hooks) => {
                var geometries:Array<PlaneGeometry> = null;
                hooks.beforeEach(() => {
                    var parameters = {
                        width: 10,
                        height: 30,
                        widthSegments: 3,
                        heightSegments: 5
                    };
                    geometries = [
                        new PlaneGeometry(),
                        new PlaneGeometry(parameters.width),
                        new PlaneGeometry(parameters.width, parameters.height),
                        new PlaneGeometry(parameters.width, parameters.height, parameters.widthSegments),
                        new PlaneGeometry(parameters.width, parameters.height, parameters.widthSegments, parameters.heightSegments)
                    ];
                });

                // INHERITANCE
                QUnit.test("Extending", (assert) => {
                    var object:PlaneGeometry = new PlaneGeometry();
                    assert.isTrue(object instanceof BufferGeometry, "PlaneGeometry extends from BufferGeometry");
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) => {
                    var object:PlaneGeometry = new PlaneGeometry();
                    assert.ok(object, "Can instantiate a PlaneGeometry.");
                });

                // PROPERTIES
                QUnit.test("type", (assert) => {
                    var object:PlaneGeometry = new PlaneGeometry();
                    assert.ok(object.type == "PlaneGeometry", "PlaneGeometry.type should be PlaneGeometry");
                });

                QUnit.todo("parameters", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                // STATIC
                QUnit.todo("fromJSON", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                // OTHERS
                QUnit.test("Standard geometry tests", (assert) => {
                    QUnitUtils.runStdGeometryTests(assert, geometries);
                });
            });
        });
    }
}