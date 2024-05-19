package three.js.test.unit.src.geometries;

import three.js.geometries.ShapeGeometry;
import three.js.extras.core.Shape;
import three.js.core.BufferGeometry;

class ShapeGeometryTest {

    public function new() {}

    public static function main() {
        QUnit.module("Geometries", () => {
            QUnit.module("ShapeGeometry", (hooks) => {
                var geometries:Array<ShapeGeometry> = null;

                hooks.beforeEach(() => {
                    var triangleShape:Shape = new Shape();
                    triangleShape.moveTo(0, -1);
                    triangleShape.lineTo(1, 1);
                    triangleShape.lineTo(-1, 1);

                    geometries = [
                        new ShapeGeometry(triangleShape),
                    ];
                });

                // INHERITANCE
                QUnit.test("Extending", (assert) => {
                    var object:ShapeGeometry = new ShapeGeometry();
                    assert.isTrue(object instanceof BufferGeometry, 'ShapeGeometry extends from BufferGeometry');
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) => {
                    var object:ShapeGeometry = new ShapeGeometry();
                    assert.ok(object != null, 'Can instantiate a ShapeGeometry.');
                });

                // PROPERTIES
                QUnit.test("type", (assert) => {
                    var object:ShapeGeometry = new ShapeGeometry();
                    assert.ok(object.type == 'ShapeGeometry', 'ShapeGeometry.type should be ShapeGeometry');
                });

                // TODO
                QUnit.todo("parameters", (assert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // PUBLIC
                QUnit.todo("toJSON", (assert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // STATIC
                QUnit.todo("fromJSON", (assert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // OTHERS
                QUnit.todo("Standard geometry tests", (assert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
            });
        });
    }
}