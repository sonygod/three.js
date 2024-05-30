package three.core;

import haxe.unit.TestCase;

class InstancedInterleavedBufferTests {

    public function new() {}

    public function testExtending() {
        var object = new InstancedInterleavedBuffer();
        assertTrue(object instanceof InterleavedBuffer, "InstancedInterleavedBuffer extends from InterleavedBuffer");
    }

    public function testInstancing() {
        var array = new Single_precision_float_array([1, 2, 3, 7, 8, 9]);
        var instance = new InstancedInterleavedBuffer(array, 3);
        assertTrue(instance.meshPerAttribute == 1, "ok");
    }

    public function testMeshPerAttribute() {
        // TODO: implement me!
        assertTrue(false, "everything's gonna be alright");
    }

    public function testIsInstancedInterleavedBuffer() {
        var object = new InstancedInterleavedBuffer();
        assertTrue(object.isInstancedInterleavedBuffer, "InstancedInterleavedBuffer.isInstancedInterleavedBuffer should be true");
    }

    public function testCopy() {
        var array = new Single_precision_float_array([1, 2, 3, 7, 8, 9]);
        var instance = new InstancedInterleavedBuffer(array, 3);
        var copiedInstance = instance.copy(instance);
        assertTrue(copiedInstance.meshPerAttribute == 1, "additional attribute was copied");
    }

    public function testClone() {
        // TODO: implement me!
        assertTrue(false, "everything's gonna be alright");
    }

    public function testToJSON() {
        // TODO: implement me!
        assertTrue(false, "everything's gonna be alright");
    }

}