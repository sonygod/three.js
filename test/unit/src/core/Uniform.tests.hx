package three.test.unit.src.core;

import haxe.unit.TestCase;
import three.core.Uniform;
import three.math.Vector3;

class UniformTests {
    public function new() {}

    public function testInstancing() {
        var a:Uniform;
        var b:Vector3 = new Vector3(x, y, z);

        a = new Uniform(5);
        assertEquals(a.value, 5, 'New constructor works with simple values');

        a = new Uniform(b);
        assertTrue(a.value.equals(b), 'New constructor works with complex values');
    }

    public function testValue() {
        // todo: implement me!
        assertTrue(false, "everything's gonna be alright");
    }

    public function testClone() {
        var a:Uniform = new Uniform(23);
        var b:Uniform = a.clone();

        assertEquals(b.value, a.value, 'clone() with simple values works');

        a = new Uniform(new Vector3(1, 2, 3));
        b = a.clone();

        assertTrue(b.value.equals(a.value), 'clone() with complex values works');
    }
}