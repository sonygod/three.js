package three.test.unit.src.core;

import haxe.unit.TestCase;
import three.core.InstancedBufferAttribute;
import three.core.BufferAttribute;

class InstancedBufferAttributeTests {
    public function new() {}

    public function testExtending():Void {
        var object:BufferAttribute = new BufferAttribute();
        assertTrue(object instanceof BufferAttribute, 'BufferAttribute extends from BufferAttribute');
    }

    public function testInstancing():Void {
        // array, itemSize
        var instance:InstancedBufferAttribute = new InstancedBufferAttribute(new Float32Array(10), 2);
        assertTrue(instance.meshPerAttribute == 1, 'Can instantiate an InstancedBufferGeometry.');

        // array, itemSize, normalized, meshPerAttribute
        instance = new InstancedBufferAttribute(new Float32Array(10), 2, false, 123);
        assertTrue(instance.meshPerAttribute == 123, 'Can instantiate an InstancedBufferGeometry with array, itemSize, normalized, and meshPerAttribute.');
    }

    public function testMeshPerAttribute():Void {
        // NOTE: This test is marked as todo in the original JavaScript code
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testIsInstancedBufferAttribute():Void {
        var object:InstancedBufferAttribute = new InstancedBufferAttribute();
        assertTrue(object.isInstancedBufferAttribute, 'InstancedBufferAttribute.isInstancedBufferAttribute should be true');
    }

    public function testCopy():Void {
        var array:Float32Array = new Float32Array([1, 2, 3, 7, 8, 9]);
        var instance:InstancedBufferAttribute = new InstancedBufferAttribute(array, 2, true, 123);
        var copiedInstance:InstancedBufferAttribute = instance.copy(instance);

        assertTrue(Std.is(copiedInstance, InstancedBufferAttribute), 'the clone has the correct type');
        assertTrue(copiedInstance.itemSize == 2, 'itemSize was copied');
        assertTrue(copiedInstance.normalized == true, 'normalized was copied');
        assertTrue(copiedInstance.meshPerAttribute == 123, 'meshPerAttribute was copied');

        for (i in 0...array.length) {
            assertTrue(copiedInstance.array[i] == array[i], 'array was copied');
        }
    }

    public function testToJSON():Void {
        // NOTE: This test is marked as todo in the original JavaScript code
        assertTrue(false, 'everything\'s gonna be alright');
    }
}