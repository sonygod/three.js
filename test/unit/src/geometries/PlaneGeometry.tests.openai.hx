package three.js.test.unit.src.geometries;

import three.js.geometries.PlaneGeometry;
import three.js.core.BufferGeometry;
import three.js.utils.QUnitUtils;

class PlaneGeometryTests {

    static function main() {
        QUnit.module("Geometries", function() {
            QUnit.module("PlaneGeometry", function(hooks) {
                var geometries:Array<PlaneGeometry> = null;
                hooks.beforeEach(function() {
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
                        new PlaneGeometry(parameters.width, parameters.height, parameters.widthSegments, parameters.heightSegments),
                    ];
                });

                // INHERITANCE
                QUnit.test("Extending", function(assert) {
                    var object:PlaneGeometry = new PlaneGeometry();
                    assert.isTrue(Std.is(object, BufferGeometry), "PlaneGeometry extends from BufferGeometry");
                });

                // INSTANCING
                QUnit.test("Instancing", function(assert) {
                    var object:PlaneGeometry = new PlaneGeometry();
                    assert.ok(object, "Can instantiate a PlaneGeometry.");
                });

                // PROPERTIES
                QUnit.test("type", function(assert) {
                    var object:PlaneGeometry = new PlaneGeometry();
                    assert.ok(object.type == "PlaneGeometry", "PlaneGeometry.type should be PlaneGeometry");
                });

                QUnit.todo("parameters", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                // STATIC
                QUnit.todo("fromJSON", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                // OTHERS
                QUnit.test("Standard geometry tests", function(assert) {
                    QUnitUtils.runStdGeometryTests(assert, geometries);
                });
            });
        });
    }
}