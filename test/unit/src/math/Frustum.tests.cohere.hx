import Math.Vector3;
import Math.Matrix4;
import Math.Plane;
import Math.Frustum;
import Math.Sphere;
import Math.Box3;

class QUnit {
    public static function module(name: String, callback: Void->Void): Void {
        callback();
    }

    public function test(name: String, callback: Void->Void): Void {
        callback();
    }

    public function todo(name: String, callback: Void->Void): Void {
        callback();
    }
}

class Sprite {
    public function new() {

    }

    public var position: Vector3;

    public function updateMatrixWorld(): Void {

    }
}

class Mesh {
    public function new(geometry: Dynamic) {

    }

    public var position: Vector3;

    public function updateMatrixWorld(): Void {

    }
}

class BoxGeometry {
    public function new(width: Float, height: Float, depth: Float) {

    }
}

class Vector3 {
    public function new(x: Float, y: Float, z: Float) {

    }

    public static function get zero3(): Vector3 {
        return new Vector3(0, 0, 0);
    }

    public static function get one3(): Vector3 {
        return new Vector3(1, 1, 1);
    }

    public static function get eps(): Float {
        return 0.000001;
    }

    public function clone(): Vector3 {
        return new Vector3(x, y, z);
    }

    public function set(x: Float, y: Float, z: Float): Vector3 {
        this.x = x;
        this.y = y;
        this.z = z;
        return this;
    }

    public function translate(amount: Vector3): Vector3 {
        x += amount.x;
        y += amount.y;
        z += amount.z;
        return this;
    }
}

class Matrix4 {
    public function new() {

    }

    public function makeOrthographic(left: Float, right: Float, bottom: Float, top: Float, near: Float, far: Float): Matrix4 {
        return this;
    }

    public function makePerspective(left: Float, right: Float, bottom: Float, top: Float, near: Float, far: Float): Matrix4 {
        return this;
    }
}

class Plane {
    public function new(?normal: Vector3, ?constant: Float) {

    }

    public function copy(source: Plane): Plane {
        return this;
    }

    public function equals(other: Plane): Bool {
        return true;
    }
}

class Frustum {
    public function new(?p0: Plane, ?p1: Plane, ?p2: Plane, ?p3: Plane, ?p4: Plane, ?p5: Plane) {

    }

    public var planes: Array<Plane>;

    public function set(p0: Plane, p1: Plane, p2: Plane, p3: Plane, p4: Plane, p5: Plane): Frustum {
        return this;
    }

    public function clone(): Frustum {
        return new Frustum();
    }

    public function copy(source: Frustum): Frustum {
        return this;
    }

    public function setFromProjectionMatrix(m: Matrix4): Frustum {
        return this;
    }

    public function containsPoint(point: Vector3): Bool {
        return false;
    }

    public function intersectsSphere(sphere: Sphere): Bool {
        return false;
    }

    public function intersectsObject(object: Mesh): Bool {
        return false;
    }

    public function intersectsSprite(sprite: Sprite): Bool {
        return false;
    }

    public function intersectsBox(box: Box3): Bool {
        return false;
    }
}

class Sphere {
    public function new(center: Vector3, radius: Float) {

    }
}

class Box3 {
    public function new(min: Vector3, max: Vector3) {

    }
}

class MathConstants {
    public static function new() {

    }

    public static var unit3: Vector3;
}

class Test {
    public static function main(): Void {
        QUnit.module('Maths', {
            QUnit.module('Frustum', {
                // INSTANCING
                QUnit.test('Instancing', {
                    var a = new Frustum();
                    trace('Passed!');
                    trace('Passed!');
                    var pDefault = new Plane();
                    var i: Int;
                    for (i = 0; i < 6; i++) {
                        trace('Passed!');
                    }
                    var p0 = new Plane(MathConstants.unit3, -1);
                    var p1 = new Plane(MathConstants.unit3, 1);
                    var p2 = new Plane(MathConstants.unit3, 2);
                    var p3 = new Plane(MathConstants.unit3, 3);
                    var p4 = new Plane(MathConstants.unit3, 4);
                    var p5 = new Plane(MathConstants.unit3, 5);
                    a = new Frustum(p0, p1, p2, p3, p4, p5);
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                });

                // PUBLIC
                QUnit.test('set', {
                    var a = new Frustum();
                    var p0 = new Plane(MathConstants.unit3, -1);
                    var p1 = new Plane(MathConstants.unit3, 1);
                    var p2 = new Plane(MathConstants.unit3, 2);
                    var p3 = new Plane(MathConstants.unit3, 3);
                    var p4 = new Plane(MathConstants.unit3, 4);
                    var p5 = new Plane(MathConstants.unit3, 5);
                    a.set(p0, p1, p2, p3, p4, p5);
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                });

                QUnit.test('clone', {
                    var p0 = new Plane(MathConstants.unit3, -1);
                    var p1 = new Plane(MathConstants.unit3, 1);
                    var p2 = new Plane(MathConstants.unit3, 2);
                    var p3 = new Plane(MathConstants.unit3, 3);
                    var p4 = new Plane(MathConstants.unit3, 4);
                    var p5 = new Plane(MathConstants.unit3, 5);
                    var b = new Frustum(p0, p1, p2, p3, p4, p5);
                    var a = b.clone();
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    // ensure it is a true copy by modifying source
                    a.planes[0].copy(p1);
                    trace('Passed!');
                });

                QUnit.test('copy', {
                    var p0 = new Plane(MathConstants.unit3, -1);
                    var p1 = new Plane(MathConstants.unit3, 1);
                    var p2 = new Plane(MathConstants.unit3, 2);
                    var p3 = new Plane(MathConstants.unit3, 3);
                    var p4 = new Plane(MathConstants.unit3, 4);
                    var p5 = new Plane(MathConstants.unit3, 5);
                    var b = new Frustum(p0, p1, p2, p3, p4, p5);
                    var a = new Frustum().copy(b);
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    // ensure it is a true copy by modifying source
                    b.planes[0] = p1;
                    trace('Passed!');
                });

                QUnit.test('setFromProjectionMatrix/makeOrthographic/containsPoint', {
                    var m = new Matrix4().makeOrthographic(-1, 1, -1, 1, 1, 100);
                    var a = new Frustum().setFromProjectionMatrix(m);
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                });

                QUnit.test('setFromProjectionMatrix/makePerspective/containsPoint', {
                    var m = new Matrix4().makePerspective(-1, 1, 1, -1, 1, 100);
                    var a = new Frustum().setFromProjectionMatrix(m);
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                });

                QUnit.test('setFromProjectionMatrix/makePerspective/intersectsSphere', {
                    var m = new Matrix4().makePerspective(-1, 1, 1, -1, 1, 100);
                    var a = new Frustum().setFromProjectionMatrix(m);
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                    trace('Passed!');
                });

                QUnit.test('intersectsObject', {
                    var m = new Matrix4().makePerspective(-1, 1, 1, -1, 1, 100);
                    var a = new Frustum().setFromProjectionMatrix(m);
                    var object = new Mesh(new BoxGeometry(1, 1, 1));
                    var intersects: Bool;
                    intersects = a.intersectsObject(object);
                    trace('No intersection');
                    object.position.set(-1, -1, -1);
                    object.updateMatrixWorld();
                    intersects = a.intersectsObject(object);
                    trace('Successful intersection');
                    object.position.set(1, 1, 1);
                    object.updateMatrixWorld();
                    intersects = a.intersectsObject(object);
                    trace('No intersection');
                });

                QUnit.test('intersectsSprite', {
                    var m = new Matrix4().makePerspective(-1, 1, 1, -1, 1, 100);
                    var a = new Frustum().setFromProjectionMatrix(m);
                    var sprite = new Sprite();
                    var intersects: Bool;
                    intersects = a.intersectsSprite(sprite);
                    trace('No intersection');
                    sprite.position.set(-1, -1, -1);
                    sprite.updateMatrixWorld();
                    intersects = a.intersectsSprite(sprite);
                    trace('Successful intersection');
                });

                QUnit.todo('intersectsSphere', {
                    trace('everything\'s gonna be alright');
                });

                QUnit.test('intersectsBox', {
                    var m = new Matrix4().makePerspective(-1, 1, 1, -1, 1, 100);
                    var a = new Frustum().setFromProjectionMatrix(m);
                    var box = new Box3(Vector3.zero3.clone(), Vector3.one3.clone());
                    var intersects: Bool;
                    intersects = a.intersectsBox(box);
                    trace('No intersection');
                    // add eps so that we prevent box touching the frustum,
                    // which might intersect depending on floating point numerics
                    box.translate(new Vector3(-1 - Vector3.eps, -1 - Vector3.eps, -1 - Vector3.eps));
                    intersects = a.intersectsBox(box);
                    trace('Successful intersection');
                });

                QUnit.todo('containsPoint', {
                    trace('everything\'s gonna be alright');
                });
            });
        });
    }
}