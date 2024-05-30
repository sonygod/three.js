import haxe.unit.TestCase;

class Maths {
    public function new() {}

    public function test() {
        // INSTANCING
        var a = new Ray();
        assertEquals(zero3, a.origin, 'Passed!');
        assertEquals(new Vector3(0, 0, -1), a.direction, 'Passed!');

        a = new Ray(two3.clone(), one3.clone());
        assertEquals(two3, a.origin, 'Passed!');
        assertEquals(one3, a.direction, 'Passed!');

        // PUBLIC
        var b = new Ray();
        b.set(one3, one3);
        assertEquals(one3, b.origin, 'Passed!');
        assertEquals(one3, b.direction, 'Passed!');

        // ... (rest of the tests)

        // intersectTriangle
        var ray = new Ray();
        var a = new Vector3(1, 1, 0);
        var b = new Vector3(0, 1, 1);
        var c = new Vector3(1, 0, 1);
        var point = new Vector3();

        // DdN == 0
        ray.set(zero3.clone(), zero3.clone());
        ray.intersectTriangle(a, b, c, false, point.copy(posInf3));
        assertEquals(posInf3, point, 'No intersection if direction == zero');

        // DdN > 0, backfaceCulling = true
        ray.set(one3.clone(), one3.clone());
        ray.intersectTriangle(a, b, c, true, point.copy(posInf3));
        assertEquals(posInf3, point, 'No intersection with backside faces if backfaceCulling is true');

        // ... (rest of the tests)

        // applyMatrix4
        var m = new Matrix4();
        a = new Ray(one3.clone(), new Vector3(0, 0, 1));
        assertEquals(a.clone().applyMatrix4(m), a, 'Passed!');

        a = new Ray(zero3.clone(), new Vector3(0, 0, 1));
        m.makeRotationZ(Math.PI);
        assertEquals(a.clone().applyMatrix4(m), a, 'Passed!');

        m.makeRotationX(Math.PI);
        var b = a.clone();
        b.direction.negate();
        var a2 = a.clone().applyMatrix4(m);
        assertEquals(b.origin.distanceTo(a2.origin), 0, 'Passed!');
        assertEquals(b.direction.distanceTo(a2.direction), 0, 'Passed!');

        a.origin = new Vector3(0, 0, 1);
        b.origin = new Vector3(0, 0, -1);
        a2 = a.clone().applyMatrix4(m);
        assertEquals(b.origin.distanceTo(a2.origin), 0, 'Passed!');
        assertEquals(b.direction.distanceTo(a2.direction), 0, 'Passed!');
    }
}