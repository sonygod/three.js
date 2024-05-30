package;

import js.QUnit.QUnit;
import js.QUnit.Module;
import js.QUnit.Test;
import js.QUnit.Todo;

import openfl.geom.Shape;
import openfl.geom.ShapeGeometry;
import openfl.geom.BufferGeometry;

class ShapeGeometryTest {
    public static function qunit() {
        var module = QUnit.module('Geometries');

        module.module('ShapeGeometry', function (hooks) {
            var geometries:Array<ShapeGeometry>; // eslint-disable-line no-unused-vars

            hooks.beforeEach(function () {
                var triangleShape = new Shape();
                triangleShape.moveTo(0, -1);
                triangleShape.lineTo(1, 1);
                triangleShape.lineTo(-1, 1);

                geometries = [
                    new ShapeGeometry(triangleShape)
                ];
            });

            // INHERITANCE
            Test('Extending', function () {
                var object = new ShapeGeometry();
                QUnit.strictEqual(
                    object instanceof BufferGeometry, true,
                    'ShapeGeometry extends from BufferGeometry'
                );
            });

            // INSTANCING
            Test('Instancing', function () {
                var object = new ShapeGeometry();
                QUnit.ok(object, 'Can instantiate a ShapeGeometry.');
            });

            // PROPERTIES
            Test('type', function () {
                var object = new ShapeGeometry();
                QUnit.ok(
                    object.type == 'ShapeGeometry',
                    'ShapeGeometry.type should be ShapeGeometry'
                );
            });

            Todo('parameters', function (assert) {
                QUnit.ok(false, 'everything\'s gonna be alright');
            });

            // PUBLIC
            Todo('toJSON', function (assert) {
                QUnit.ok(false, 'everything\'s gonna be alright');
            });

            // STATIC
            Todo('fromJSON', function (assert) {
                QUnit.ok(false, 'everything\'s gonna be alright');
            });

            // OTHERS
            Todo('Standard geometry tests', function (assert) {
                QUnit.ok(false, 'everything\'s gonna be alright');
            });
        });
    }
}