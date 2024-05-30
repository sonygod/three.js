import js.Browser;
import js.Lib;
import three.js.test.unit.src.math.Box3;
import three.js.test.unit.src.math.Sphere;
import three.js.test.unit.src.math.Triangle;
import three.js.test.unit.src.math.Plane;
import three.js.test.unit.src.math.Vector3;
import three.js.test.unit.src.math.Matrix4;
import three.js.test.unit.src.objects.Mesh;
import three.js.test.unit.src.core.BufferAttribute;
import three.js.test.unit.src.geometries.BoxGeometry;
import three.js.test.unit.src.geometries.SphereGeometry;
import three.js.test.utils.math-constants;

class Box3Tests {
    static function main() {
        var QUnit = Browser.window.QUnit;

        QUnit.module('Maths', () -> {
            QUnit.module('Box3', () -> {
                // INSTANCING
                QUnit.test('Instancing', (assert) -> {
                    var a = new Box3();
                    assert.ok(a.min.distanceTo(math-constants.posInf3) < 0.0001, 'Passed!');
                    assert.ok(a.max.distanceTo(math-constants.negInf3) < 0.0001, 'Passed!');

                    a = new Box3(math-constants.zero3.clone(), math-constants.zero3.clone());
                    assert.ok(a.min.equals(math-constants.zero3), 'Passed!');
                    assert.ok(a.max.equals(math-constants.zero3), 'Passed!');

                    a = new Box3(math-constants.zero3.clone(), math-constants.one3.clone());
                    assert.ok(a.min.equals(math-constants.zero3), 'Passed!');
                    assert.ok(a.max.equals(math-constants.one3), 'Passed!');
                });

                // PUBLIC STUFF
                QUnit.test('isBox3', (assert) -> {
                    var a = new Box3();
                    assert.ok(a.isBox3, 'Passed!');

                    var b = new Sphere();
                    assert.ok(!b.isBox3, 'Passed!');
                });

                // ... rest of the tests ...

                // EQUALS
                QUnit.test('equals', (assert) -> {
                    var a = new Box3();
                    var b = new Box3();
                    assert.ok(b.equals(a), 'Passed!');
                    assert.ok(a.equals(b), 'Passed!');

                    a = new Box3(math-constants.one3, math-constants.two3);
                    b = new Box3(math-constants.one3, math-constants.two3);
                    assert.ok(b.equals(a), 'Passed!');
                    assert.ok(a.equals(b), 'Passed!');

                    a = new Box3(math-constants.one3, math-constants.two3);
                    b = a.clone();
                    assert.ok(b.equals(a), 'Passed!');
                    assert.ok(a.equals(b), 'Passed!');

                    a = new Box3(math-constants.one3, math-constants.two3);
                    b = new Box3(math-constants.one3, math-constants.one3);
                    assert.ok(!b.equals(a), 'Passed!');
                    assert.ok(!a.equals(b), 'Passed!');

                    a = new Box3();
                    b = new Box3(math-constants.one3, math-constants.one3);
                    assert.ok(!b.equals(a), 'Passed!');
                    assert.ok(!a.equals(b), 'Passed!');
                });
            });
        });
    }
}